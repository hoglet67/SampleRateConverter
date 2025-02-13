-- Audio Sample Rate Converter for BeebFPGA using a Polyphase filter
--
-- Copyright (c) 2025 David Banks
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- * Redistributions of source code must retain the above copyright notice,
--   this list of conditions and the following disclaimer.
--
-- * Redistributions in synthesized form must reproduce the above copyright
--   notice, this list of conditions and the following disclaimer in the
--   documentation and/or other materials provided with the distribution.
--
-- * Neither the name of the author nor the names of other contributors may
--   be used to endorse or promote products derived from this software without
--   specific prior written agreement from the author.
--
-- * License is granted for non-commercial use only.  A fee may not be charged
--   for redistributions as source code or in synthesized/hardware form without
--   specific prior written agreement from the author.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sample_rate_converter_pkg.all;

entity sample_rate_converter is
    generic (
        OUTPUT_RATE       : integer;
        OUTPUT_WIDTH      : integer;
        FILTER_NTAPS      : integer;
        FILTER_L          : t_int_array;
        FILTER_M          : integer;
        CHANNEL_TYPE      : t_channel_type_array;
        BUFFER_A_WIDTH    : integer;
        COEFF_A_WIDTH     : integer;
        ACCUMULATOR_WIDTH : integer;
        BUFFER_SIZE       : t_int_array
        );
    port (
        clk               : in  std_logic;
        clk_en            : in  std_logic := '1';
        reset_n           : in  std_logic;

        -- Master volume
        volume            : in  unsigned(7 downto 0);

        -- Input Channels
        channel_clken     : in  std_logic_vector(NUM_CHANNELS - 1 downto 0) := (others => '1');
        channel_load      : in  std_logic_vector(NUM_CHANNELS - 1 downto 0) := (others => '0');
        channel_in        : in  t_sample_array;

        -- Stereo output
        mixer_load        : out std_logic;
        mixer_l           : out signed(OUTPUT_WIDTH - 1 downto 0);
        mixer_r           : out signed(OUTPUT_WIDTH - 1 downto 0)
        );
end entity;

architecture rtl of sample_rate_converter is

    -- ------------------------------------------------------------------------------
    -- Pre-calculate M MOD L and M DIV L for each channel
    -- ------------------------------------------------------------------------------

    function init_m_mod_l(m : in integer; l : in t_int_array) return t_int_array is
        variable ret : t_int_array;
    begin
        for i in 0 to NUM_CHANNELS - 1 loop
            ret(i) := m mod l(i);
        end loop;
        return ret;
    end function;

    function init_m_div_l(m : in integer; l : in t_int_array) return t_int_array is
        variable ret : t_int_array;
    begin
        for i in 0 to NUM_CHANNELS - 1 loop
            ret(i) := m / l(i);
        end loop;
        return ret;
    end function;

    constant M_MOD_L : t_int_array := init_m_mod_l(FILTER_M, FILTER_L);

    constant M_DIV_L : t_int_array := init_m_div_l(FILTER_M, FILTER_L);

    -- ------------------------------------------------------------------------------
    -- Input Data Latches
    -- ------------------------------------------------------------------------------

    -- A single register to capture input data before it's writtem to the RAM
    signal channel_data : t_sample_array;

    -- A register to indicate data is pending on the channel
    signal channel_dav : std_logic_vector(NUM_CHANNELS - 1 downto 0);

    -- A function that returns true if all bits of the SLV are zero, or the SLV is an empty slice
    function all_bits_clear(slv : in std_logic_vector; lo : integer; hi : integer) return boolean is
        variable ret : boolean;
    begin
        ret := true;
        if hi >= lo then
            for i in lo to hi loop
                if slv(i) = '1' then
                    ret := false;
                end if;
            end loop;
        end if;
        return ret;
    end function;

    -- ------------------------------------------------------------------------------
    -- Coefficient ROM
    -- ------------------------------------------------------------------------------

    -- Coefficient Block ROM

    -- Coefficient ROM Ports
    signal coeff_rd_addr : unsigned(COEFF_A_WIDTH - 1 downto 0) := (others => '0');
    signal coeff_rd_data : signed(SAMPLE_WIDTH - 1 downto 0) := (others => '0');

    -- Coefficient Pointers
    type t_coeff_addr_array is array(0 to NUM_CHANNELS - 1)
        of unsigned(COEFF_A_WIDTH downto 0);

    signal k : t_coeff_addr_array :=  (others => (others => '0'));

    -- ------------------------------------------------------------------------------
    -- Buffer RAM
    -- ------------------------------------------------------------------------------

    -- Buffer RAM Ports
    signal buffer_wr_addr : unsigned(BUFFER_A_WIDTH - 1 downto 0) := (others => '0');
    signal buffer_rd_addr : unsigned(BUFFER_A_WIDTH - 1 downto 0) := (others => '0');
    signal buffer_wr_data : signed(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
    signal buffer_rd_data : signed(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
    signal buffer_we      : std_logic := '0';

    -- A function to initialize the base address of each buffer from the passed-in size
    function init_buffer_base(i_buffer_size : in t_int_array)
        return t_int_array is
        variable tmp : t_int_array;
        variable sum : integer;
    begin
        sum := 0;
        for i in 0 to NUM_CHANNELS - 1 loop
            tmp(i) := sum;
            sum := sum + i_buffer_size(i);
        end loop;
        return tmp;
    end function;

    -- The base address of each buffer
    constant BUFFER_BASE : t_int_array := init_buffer_base(BUFFER_SIZE);

    -- Buffer read / write pointers
    type t_buffer_addr_array is array(0 to NUM_CHANNELS - 1)
        of unsigned(BUFFER_A_WIDTH - 1 downto 0);
    signal rd_addr : t_buffer_addr_array;
    signal wr_addr : t_buffer_addr_array;

    -- The initial offset offset between read and write pointers
    -- (initially the buffer will contain this many zero)
    constant RD_WR_OFFSET : integer := 4;

    -- ------------------------------------------------------------------------------
    -- State variables
    -- ------------------------------------------------------------------------------

    type t_state_main is (
        idle,
        setup,
        calculate,
        save,
        stall1,
        stall2,
        stall3,
        scale_lsb,
        scale_msb,
        complete
    );

    signal state 	: 	t_state_main := idle;
    signal current_channel : unsigned(1 downto 0) := (others => '0'); -- should depend on NUM_CHANNELS!
    signal multiply_count : unsigned(COEFF_A_WIDTH - 1 downto 0) := (others => '0');
    signal coeff_index : unsigned(COEFF_A_WIDTH downto 0) := (others => '0');
    signal sample_addr : unsigned(BUFFER_A_WIDTH - 1 downto 0) := (others => '0');
    signal rate_counter : unsigned(9 downto 0); -- TODO: determine width from output rate

    -- ------------------------------------------------------------------------------
    -- DSP
    -- ------------------------------------------------------------------------------


    type t_dsp_op is (
        dsp_idle,
        dsp_setup,
        dsp_mult_accumulate,
        dsp_save,
        dsp_scale_lsb_l,
        dsp_scale_lsb_r,
        dsp_scale_lsb_mono,
        dsp_scale_msb_l,
        dsp_scale_msb_r,
        dsp_scale_msb_mono,
        dsp_output
        );

    type t_dsp_ctrl is array(0 to 4) of t_dsp_op;

    signal dsp_ctrl : t_dsp_ctrl  := (others => dsp_idle);

    signal mult_a_in       : signed(SAMPLE_WIDTH - 1 downto 0);
    signal mult_b_in       : signed(SAMPLE_WIDTH - 1 downto 0);
    signal mult_out        : signed(SAMPLE_WIDTH * 2 - 1 downto 0);
    signal accumulator     : signed(ACCUMULATOR_WIDTH - 1 downto 0);
    signal channel_mag_lsb : signed(SAMPLE_WIDTH - 1 downto 0); -- will always hold a positive value
    signal channel_mag_msb : signed(SAMPLE_WIDTH - 1 downto 0); -- will always hold a positive value
    signal channel_sign    : std_logic;
    signal scale_factor    : signed(SAMPLE_WIDTH - 1 downto 0);
    signal mixer_sum_l     : signed(SAMPLE_WIDTH * 2 - 1 downto 0) := to_signed(0, SAMPLE_WIDTH * 2);
    signal mixer_sum_r     : signed(SAMPLE_WIDTH * 2 - 1 downto 0) := to_signed(0, SAMPLE_WIDTH * 2);

    signal debug_state : std_logic_vector(3 downto 0);
begin

    debug_state <= std_logic_vector(to_unsigned(t_state_main'pos(state), 4));

    ----------------------------------------------------------------------------------
    -- Channel input latches and buffer writing
    ----------------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                buffer_we <= '0';
                for i in 0 to NUM_CHANNELS - 1 loop
                    if reset_n = '0' then
                        wr_addr(i) <= to_unsigned(BUFFER_BASE(i) + RD_WR_OFFSET, BUFFER_A_WIDTH);
                        channel_dav(i) <= '0';
                        channel_data(i) <= to_signed(0, SAMPLE_WIDTH);
                    else
                        -- Latch the channel input sample as soon as it appears
                        if channel_dav(i) = '0' and channel_clken(i) = '1' and channel_load(i) = '1' then
                            channel_dav(i) <= '1';
                            channel_data(i) <= channel_in(i);
                        end if;
                        -- build a priority encode to serialize multiple simultaneous buffer writes
                        if channel_dav(i) = '1' and all_bits_clear(channel_dav, 0, i - 1) then
                            buffer_wr_addr <= wr_addr(i);
                            buffer_wr_data <= channel_data(i);
                            buffer_we <= '1';
                            channel_dav(i) <= '0';
                            -- Buffers no longer have any alignment constraints
                            if wr_addr(i) = BUFFER_BASE(i) + BUFFER_SIZE(i) - 1 then
                                wr_addr(i) <= to_unsigned(BUFFER_BASE(i), BUFFER_A_WIDTH);
                            else
                                wr_addr(i) <= wr_addr(i) + 1;
                            end if;
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- Channel state machine
    ----------------------------------------------------------------------------------

    process(clk)
        variable tmp_coeff  : unsigned(COEFF_A_WIDTH downto 0);
        variable tmp_k      : unsigned(COEFF_A_WIDTH downto 0);
        variable tmp_i      : unsigned(BUFFER_A_WIDTH - 1 downto 0);
        variable buffer_end : integer;
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                --
                if reset_n = '0' then
                    dsp_ctrl <= (others => dsp_idle);
                    rate_counter <= (others => '1');
                    state        <= idle;
                    for i in 0 to NUM_CHANNELS - 1 loop
                        k(i) <= to_unsigned(0, COEFF_A_WIDTH + 1);
                        rd_addr(i) <= to_unsigned(BUFFER_BASE(i), BUFFER_A_WIDTH);
                    end loop;
                else
                    -- Precalculate w to save some typing
                    buffer_end := BUFFER_BASE(to_integer(current_channel)) + BUFFER_SIZE(to_integer(current_channel)) - 1;
                    -- Control signals delayed to match the pipeline depth
                    for i in dsp_ctrl'length - 1 downto 1 loop
                        dsp_ctrl(i) <= dsp_ctrl(i - 1);
                    end loop;
                    dsp_ctrl(0) <= dsp_idle;
                    -- When this reaches zero, it's time to start computing a new output sample
                    if rate_counter = 0 then
                        rate_counter <= to_unsigned(OUTPUT_RATE - 1, rate_counter'length);
                    else
                        rate_counter <= rate_counter - 1;
                    end if;
                    case state is
                        when idle =>
                            current_channel <= (others => '0');
                            if rate_counter = 0 then
                                -- Output the current output sample
                                dsp_ctrl(0) <= dsp_output;
                                -- Start calculating the next output sample
                                state <= setup;
                            end if;
                        when setup =>
                            coeff_index <= k(to_integer(current_channel));
                            multiply_count <= to_unsigned(FILTER_NTAPS / FILTER_L(to_integer(current_channel)) - 1, COEFF_A_WIDTH);
                            sample_addr <= rd_addr(to_integer(current_channel));
                            dsp_ctrl(0) <= dsp_setup;
                            state <= calculate;
                        when calculate =>
                            buffer_rd_addr <= sample_addr;
                            tmp_coeff := coeff_index;
                            if tmp_coeff >= FILTER_NTAPS / 2 then
                                tmp_coeff := FILTER_NTAPS - 1 - tmp_coeff;
                            end if;
                            coeff_rd_addr <= tmp_coeff(COEFF_A_WIDTH - 1 downto 0);
                            if sample_addr = BUFFER_BASE(to_integer(current_channel)) then
                                sample_addr <= to_unsigned(buffer_end, BUFFER_A_WIDTH);
                            else
                                sample_addr <= sample_addr - 1;
                            end if;
                            coeff_index <= coeff_index + FILTER_L(to_integer(current_channel));
                            dsp_ctrl(0) <= dsp_mult_accumulate;
                            if multiply_count = 0 then
                                state <= save;
                            else
                                multiply_count <= multiply_count - 1;
                            end if;
                        when save =>
                            dsp_ctrl(0) <= dsp_save;
                            state <= stall1;
                        when stall1 =>
                            state <= stall2;
                        when stall2 =>
                            state <= stall3;
                        when stall3 =>
                            state <= scale_lsb;
                        when scale_lsb =>
                            case(CHANNEL_TYPE(to_integer(current_channel))) is
                                when left_channel =>
                                    dsp_ctrl(0) <= dsp_scale_lsb_l;
                                when right_channel =>
                                    dsp_ctrl(0) <= dsp_scale_lsb_r;
                                when mono =>
                                    dsp_ctrl(0) <= dsp_scale_lsb_mono;
                            end case;
                            state <= scale_msb;
                        when scale_msb =>
                            case(CHANNEL_TYPE(to_integer(current_channel))) is
                                when left_channel =>
                                    dsp_ctrl(0) <= dsp_scale_msb_l;
                                when right_channel =>
                                    dsp_ctrl(0) <= dsp_scale_msb_r;
                                when mono =>
                                    dsp_ctrl(0) <= dsp_scale_msb_mono;
                            end case;
                            state <= complete;
                        when complete =>
                            -- k += M % L;
                            -- if (k >= L) {
                            --   k -= L;
                            --   n += (M / L) + 1;
                            -- } else {
                            --   n += (M / L);
                            -- }
                            tmp_k := k(to_integer(current_channel)) + M_MOD_L(to_integer(current_channel));
                            tmp_i := rd_addr(to_integer(current_channel)) + to_unsigned(M_DIV_L(to_integer(current_channel)), BUFFER_A_WIDTH);
                            if tmp_k >= FILTER_L(to_integer(current_channel)) then
                                tmp_k := tmp_k - FILTER_L(to_integer(current_channel));
                                tmp_i := tmp_i + 1;
                            end if;
                            k(to_integer(current_channel)) <= tmp_k;
                            if tmp_i > buffer_end then
                                tmp_i := tmp_i - BUFFER_SIZE(to_integer(current_channel));
                            end if;
                            rd_addr(to_integer(current_channel)) <= tmp_i;
                            current_channel <= current_channel + 1;
                            if current_channel = NUM_CHANNELS - 1 then
                                state <= idle;
                            else
                                state <= setup;
                            end if;
                     end case;
                 end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 0 : Block RAM
    ----------------------------------------------------------------------------------

    -- Single Port Coefficient ROM
    inst_coeff_rom : entity work.coeff_rom
        generic map (
            A_WIDTH => COEFF_A_WIDTH,
            D_WIDTH => SAMPLE_WIDTH
            )
        port map (
            clk => clk,
            clk_en => clk_en,
            addr => coeff_rd_addr,
            data => coeff_rd_data
            );


    -- Dual Port Buffer RAM
    inst_buffer_ram : entity work.buffer_ram
        generic map (
            A_WIDTH => BUFFER_A_WIDTH,
            D_WIDTH => SAMPLE_WIDTH
            )
        port map (
            clk => clk,
            clk_en => clk_en,
            we => buffer_we,
            wr_addr => buffer_wr_addr,
            wr_data => buffer_wr_data,
            rd_addr => buffer_rd_addr,
            rd_data => buffer_rd_data
            );

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 1: Multiply input registes
    ----------------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                case dsp_ctrl(1) is
                    when dsp_setup =>
                        -- Calculate a scale factor that is volume(8 bits) * L
                        mult_a_in <= to_signed(to_integer(volume), SAMPLE_WIDTH);
                        mult_b_in <= to_signed(FILTER_L(to_integer(current_channel)), SAMPLE_WIDTH);
                    when dsp_scale_lsb_l | dsp_scale_lsb_r | dsp_scale_lsb_mono =>
                        -- Multiply the bottom half of the channel magnitude by the scale factor
                        mult_a_in <= channel_mag_lsb;
                        mult_b_in <= scale_factor;
                    when dsp_scale_msb_l | dsp_scale_msb_r | dsp_scale_msb_mono =>
                        -- Multiply the top half of the channel magnitude by the scale factor
                        mult_a_in <= channel_mag_msb;
                        mult_b_in <= scale_factor;
                    when others =>
                        -- Default to getting operand from the block RAMs
                        mult_a_in <= coeff_rd_data;
                        mult_b_in <= buffer_rd_data;
                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 2 - 18x18 Multiply
    ----------------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                mult_out <= mult_a_in * mult_b_in;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 3a - Accumulator
    ----------------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                if dsp_ctrl(3) = dsp_setup then
                    -- Clear the accumulator
                    accumulator <= to_signed(0, accumulator'length);
                elsif dsp_ctrl(3) = dsp_mult_accumulate then
                    -- Accumulate the next Sample * Coefficient value
                    accumulator <= accumulator + mult_out;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 3b - calculate scale factor
    ----------------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                if dsp_ctrl(3) = dsp_setup then
                    -- Save the volume * L scale factor
                    scale_factor <= mult_out(SAMPLE_WIDTH - 1 downto 0);
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 3c - mix the left channel
    ----------------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                case dsp_ctrl(3) is
                    when dsp_scale_lsb_l | dsp_scale_lsb_mono =>
                        -- Update the mixer sum (left) with the LSB partial product result
                        if channel_sign = '0' then
                            mixer_sum_l <= mixer_sum_l + mult_out;
                        else
                            mixer_sum_l <= mixer_sum_l - mult_out;
                        end if;
                    when dsp_scale_msb_l | dsp_scale_msb_mono =>
                        -- Update the mixer sum (left) with the MSB partial product result
                        -- This needs scaling by 2**(SAMPLE_WIDTH-1)
                        if channel_sign = '0' then
                            mixer_sum_l(SAMPLE_WIDTH * 2 - 1 downto SAMPLE_WIDTH - 1) <=
                            mixer_sum_l(SAMPLE_WIDTH * 2 - 1 downto SAMPLE_WIDTH - 1) + mult_out(SAMPLE_WIDTH - 1 downto 0);
                        else
                            mixer_sum_l(SAMPLE_WIDTH * 2 - 1 downto SAMPLE_WIDTH - 1) <=
                            mixer_sum_l(SAMPLE_WIDTH * 2 - 1 downto SAMPLE_WIDTH - 1) - mult_out(SAMPLE_WIDTH - 1 downto 0);
                        end if;
                    when dsp_output =>
                        mixer_sum_l <= to_signed(0, mixer_sum_l'length);
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 3d - mix the right channel
    ----------------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                case dsp_ctrl(3) is
                    when dsp_scale_lsb_r | dsp_scale_lsb_mono =>
                        -- Update the mixer sum (right) with the LSB partial product result
                        if channel_sign = '0' then
                            mixer_sum_r <= mixer_sum_r + mult_out;
                        else
                            mixer_sum_r <= mixer_sum_r - mult_out;
                        end if;
                    when dsp_scale_msb_r | dsp_scale_msb_mono =>
                        -- Update the mixer sum (right) with the MSB partial product result
                        -- This needs scaling by 2**(SAMPLE_WIDTH-1)
                        if channel_sign = '0' then
                            mixer_sum_r(SAMPLE_WIDTH * 2 - 1 downto SAMPLE_WIDTH - 1) <=
                            mixer_sum_r(SAMPLE_WIDTH * 2 - 1 downto SAMPLE_WIDTH - 1) + mult_out(SAMPLE_WIDTH - 1 downto 0);
                        else
                            mixer_sum_r(SAMPLE_WIDTH * 2 - 1 downto SAMPLE_WIDTH - 1) <=
                            mixer_sum_r(SAMPLE_WIDTH * 2 - 1 downto SAMPLE_WIDTH - 1) - mult_out(SAMPLE_WIDTH - 1 downto 0);
                        end if;
                    when dsp_output =>
                        mixer_sum_r <= to_signed(0, mixer_sum_r'length);
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 3e - update the output
    ----------------------------------------------------------------------------------

    -- Note: mixer_sum_l is 2 * SAMPLE_WIDTH bits wide (=36)
    --
    -- It contains a signed value that is the sum of all N (=4) channels
    --
    -- And each channel is 18-bit signed value that has been scaled by:
    --     fixed filter gain (=384) * volume (0..255)
    --
    -- This now needs mapping to a final value that us OUTPUT_WIDTH (=20) bits wide
    --
    -- We currently do that by taking bits 35..16
    --
    -- If you use the left most bits when mapping mixer_sum to the
    -- final output then a input channel of 50% (+65536) with a FG of
    -- 384 and vol of 63 (25%) gives a final output of +3024 which is about 0.5%.
    --
    -- Extrapolating, an 100% input (+131072) FG of 256 and a vol of 256 would give
    -- +16384 on a 20 bit signed output which is 3.125 (1/32).
    --
    -- This suggest a final gain of 32 (a shift of 5 bits) is about right
    --
    -- TODO: make the FILTER_GAIN (=384) a generic and calculate the bit slice
    -- TODO: recalculate the filter with a FILTER_GAIN of 256
    -- TODO: clip values that are too large
    -- TODO: somehow calculate the shift value automatically

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                case dsp_ctrl(3) is
                    when dsp_output =>
                        -- Use the left most bits when mapping mixer_sum
                        -- mixer_l     <= mixer_sum_l(mixer_sum_l'left downto mixer_sum_l'left - OUTPUT_WIDTH + 1);
                        -- mixer_r     <= mixer_sum_r(mixer_sum_r'left downto mixer_sum_r'left - OUTPUT_WIDTH + 1);
                        mixer_l     <= mixer_sum_l(mixer_sum_l'left - 5  downto mixer_sum_l'left - 5 - OUTPUT_WIDTH + 1);
                        mixer_r     <= mixer_sum_r(mixer_sum_l'left - 5  downto mixer_sum_l'left - 5 - OUTPUT_WIDTH + 1);
                        mixer_load  <= '1';
                    when others =>
                        mixer_load  <= '0';
                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 4 - save the filter result in sign/magnitude format
    --
    --
    -- Note: this feeds back to stage 1, so the state machine must insert three
    -- stall states before usimg the channel sum/magnitude values
    ----------------------------------------------------------------------------------

    process(clk)
        variable tmp : signed(SAMPLE_WIDTH * 2 - 1 downto 0);
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                if dsp_ctrl(4) = dsp_save then
                    tmp := accumulator(ACCUMULATOR_WIDTH - 1 downto SAMPLE_WIDTH);
                    if tmp < 0 then
                        channel_sign <= '1';
                        tmp := -tmp;
                    else
                        channel_sign <= '0';
                    end if;
                    channel_mag_lsb <= signed("0" & std_logic_vector(tmp(SAMPLE_WIDTH     - 2 downto                0)));
                    channel_mag_msb <= signed("0" & std_logic_vector(tmp(SAMPLE_WIDTH * 2 - 3 downto SAMPLE_WIDTH - 1)));
                end if;
            end if;
        end if;
    end process;

end architecture;
