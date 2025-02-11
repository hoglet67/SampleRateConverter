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
    -- Buffer ROM
    -- ------------------------------------------------------------------------------

    -- Buffer Block RAM
    type t_buffer_ram is array(0 to 2**BUFFER_A_WIDTH - 1) of signed(SAMPLE_WIDTH - 1 downto 0);
    shared variable buffer_ram : t_buffer_ram := (others => (others => '0'));

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
        init,
        calculate,
        scale,
        transfer
    );

    signal state 	: 	t_state_main := init;
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
        dsp_clear,
        dsp_multiply,
        dsp_rescale,
        dsp_update_l,
        dsp_update_r,
        dsp_update_mono,
        dsp_output
        );

    type t_dsp_ctrl is array(0 to 4) of t_dsp_op;

    signal dsp_ctrl : t_dsp_ctrl  := (others => dsp_idle);

    signal mult_a_in    : signed(SAMPLE_WIDTH - 1 downto 0);
    signal mult_b_in    : signed(SAMPLE_WIDTH - 1 downto 0);
    signal mult_out     : signed(SAMPLE_WIDTH * 2 - 1 downto 0);
    signal accumulator  : signed(ACCUMULATOR_WIDTH - 1 downto 0);

    signal mixer_tmp_l  : signed(OUTPUT_WIDTH - 1 downto 0) := to_signed(0, OUTPUT_WIDTH);
    signal mixer_tmp_r  : signed(OUTPUT_WIDTH - 1 downto 0) := to_signed(0, OUTPUT_WIDTH);

    -- For testing purposes
    signal channel_data_i : signed(SAMPLE_WIDTH - 1 downto 0);

begin

    -- For testing, a it's hard to see inside arrays
    channel_data_i <= channel_data(to_integer(current_channel));

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                if reset_n = '0' then
                    for i in 0 to NUM_CHANNELS - 1 loop
                        wr_addr(i) <= to_unsigned(BUFFER_BASE(i) + RD_WR_OFFSET, BUFFER_A_WIDTH);
                        channel_dav(i) <= '0';
                        channel_data(i) <= to_signed(0, SAMPLE_WIDTH);
                    end loop;
                else
                    -- Latch the channel input sample as soon as it appears
                    for i in 0 to NUM_CHANNELS - 1 loop
                        if channel_clken(i) = '1' and channel_load(i) = '1' and channel_dav(i) = '0' then
                            channel_dav(i) <= '1';
                            channel_data(i) <= channel_in(i);
                        end if;
                    end loop;
                    buffer_we <= '0';
                    -- Buffer writing
                    for i in 0 to NUM_CHANNELS - 1 loop
                        -- build a priority encode to serialize multiple simultaneous buffer writes
                        if channel_dav(i) = '1' and all_bits_clear(channel_dav, 0, i - 1) then
                            buffer_wr_addr <= wr_addr(i);
                            buffer_wr_data <= channel_data(i);
                            buffer_we <= '1';
                            channel_dav(i) <= '0';
                            -- This assume each buffer is aligned on a 2^BUFFER_WIDTH boundary
                            if wr_addr(i) = BUFFER_BASE(i) + BUFFER_SIZE(i) - 1 then
                                wr_addr(i) <= to_unsigned(BUFFER_BASE(i), BUFFER_A_WIDTH);
                            else
                                wr_addr(i) <= wr_addr(i) + 1;
                            end if;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;




    -- Channel state machine
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
                                state <= init;
                            end if;
                        when init =>
                            coeff_index <= k(to_integer(current_channel));
                            multiply_count <= to_unsigned(FILTER_NTAPS / FILTER_L(to_integer(current_channel)) - 1, COEFF_A_WIDTH);
                            sample_addr <= rd_addr(to_integer(current_channel));
                            dsp_ctrl(0) <= dsp_clear;
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
                            dsp_ctrl(0) <= dsp_multiply;
                            if multiply_count = 0 then
                                state <= scale;
                            else
                                multiply_count <= multiply_count - 1;
                            end if;
                        when scale =>
                            dsp_ctrl(0) <= dsp_rescale;
                            state <= transfer;
                        when transfer =>
                            case(CHANNEL_TYPE(to_integer(current_channel))) is
                                when left_channel =>
                                    dsp_ctrl(0) <= dsp_update_l;
                                when right_channel =>
                                    dsp_ctrl(0) <= dsp_update_r;
                                when mono =>
                                    dsp_ctrl(0) <= dsp_update_mono;
                            end case;
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
                                state <= init;
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
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                if buffer_we = '1' then
                    buffer_ram(to_integer(buffer_wr_addr)) := buffer_wr_data;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                buffer_rd_data <= buffer_ram(to_integer(buffer_rd_addr));
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 1: Multiply input registes
    ----------------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                if dsp_ctrl(1) = dsp_rescale then
                    -- HACK ALERT: The +6 is to avoid clipping because
                    -- the filter has an effective gain of 384/L. We
                    -- really need higher precision here, especially
                    -- if we want an external volume control as well.
                    mult_a_in <= accumulator(SAMPLE_WIDTH * 2 - 1 + 6 downto SAMPLE_WIDTH + 6);
                    mult_b_in <= to_signed(FILTER_L(to_integer(current_channel)), SAMPLE_WIDTH);
                else
                    mult_a_in <= coeff_rd_data;
                    mult_b_in <= buffer_rd_data;
                end if;
                mult_out <= mult_a_in * mult_b_in;
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
    -- DSP pipeline stage 3 - 54 bit Sum (accumulating multiplies)
    ----------------------------------------------------------------------------------

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                if dsp_ctrl(3) = dsp_clear then
                    accumulator <= to_signed(0, accumulator'length);
                elsif dsp_ctrl(3) = dsp_multiply then
                    accumulator <= accumulator + mult_out;
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------------
    -- DSP pipeline stage 4 - Updating mixer output
    ----------------------------------------------------------------------------------

    -- Note: it might make sense to split this stage

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                -- HACK ALERT: The +6 is to avoid clipping because
                -- the filter has an effective gain of 384/L. We
                -- really need higher precision here, especially
                -- if we want an external volume control as well.
                if dsp_ctrl(4) = dsp_update_l or dsp_ctrl(4) = dsp_update_mono then
                    mixer_tmp_l <= mixer_tmp_l + accumulator(SAMPLE_WIDTH * 2 - 1 + 6 downto SAMPLE_WIDTH + 6);
                end if;
                if dsp_ctrl(4) = dsp_update_r or dsp_ctrl(4) = dsp_update_mono then
                    mixer_tmp_r <= mixer_tmp_r + accumulator(SAMPLE_WIDTH * 2 - 1 + 6 downto SAMPLE_WIDTH + 6);
                end if;
                if dsp_ctrl(4) = dsp_output then
                    mixer_l     <= mixer_tmp_l;
                    mixer_r     <= mixer_tmp_r;
                    mixer_load  <= '1';
                    mixer_tmp_l <= to_signed(0, OUTPUT_WIDTH);
                    mixer_tmp_r <= to_signed(0, OUTPUT_WIDTH);
                else
                    mixer_load  <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture;
