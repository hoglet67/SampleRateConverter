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
        COEFF_BASE        : integer;
        OUTPUT_RATE       : integer;
        FILTER_L          : t_int_array;
        FILTER_M          : integer;
        FILTER_NTAPS      : t_int_array;
        BUFFER_A_WIDTH    : integer;
        COEFF_A_WIDTH     : integer;
        ACCUMULATOR_WIDTH : integer;
        BUFFER_WIDTH      : t_int_array
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
        mixer_left        : out signed(SAMPLE_WIDTH - 1 downto 0);
        mixer_right       : out signed(SAMPLE_WIDTH - 1 downto 0)
        );
end entity;

architecture rtl of sample_rate_converter is

    -- ------------------------------------------------------------------------------
    -- Input Data Latches
    -- ------------------------------------------------------------------------------

    -- A single register to capture input data before it's writtem to the RAM
    signal r_channel_data : t_sample_array;

    -- A register to indicate data is pending on the channel
    signal r_channel_dav : std_logic_vector(NUM_CHANNELS - 1 downto 0);

    -- A function that returns true if all bits of the SLV are zero, or the SLV is an empty slice
    function all_bits_clear(slv : in std_logic_vector) return boolean is
        variable ret : boolean;
    begin
        ret := true;
        for i in slv'range loop
            if slv(i) = '1' then
                ret := false;
            end if;
        end loop;
        return ret;
    end function;

    -- ------------------------------------------------------------------------------
    -- Coefficient ROM
    -- ------------------------------------------------------------------------------

    -- TODO: Add init function from file

    -- Coefficient Block ROM
    type t_coeff_rom is array(0 to 2**COEFF_A_WIDTH - 1) of signed(SAMPLE_WIDTH - 1 downto 0);
    shared variable coeff_rom : t_coeff_rom := (others => (others => '0'));

    -- Coefficient ROM Ports
    signal coeff_rom_addr : unsigned(COEFF_A_WIDTH - 1 downto 0) := (others => '0');
    signal coeff_rom_data : signed(SAMPLE_WIDTH - 1 downto 0) := (others => '0');

    -- Coefficient Pointers
    type t_coeff_addr_array is array(0 to NUM_CHANNELS - 1)
        of unsigned(COEFF_A_WIDTH - 1 downto 0);

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

    -- A function to initialize the base address of each buffer from the passed-in widths
    function init_buffer_base(i_buffer_width : in t_int_array)
        return t_int_array is
        variable tmp : t_int_array;
        variable sum : integer;
    begin
        sum := 0;
        for i in 0 to NUM_CHANNELS - 1 loop
            tmp(i) := sum;
            sum := sum + 2 ** i_buffer_width(i);
        end loop;
        return tmp;
    end function;

    -- The base address of each buffer
    constant BUFFER_BASE : t_int_array := init_buffer_base(BUFFER_WIDTH);

    -- Buffer read / write pointers
    type t_buffer_addr_array is array(0 to NUM_CHANNELS - 1)
        of unsigned(BUFFER_A_WIDTH - 1 downto 0);
    signal r_rd_addr : t_buffer_addr_array;
    signal r_wr_addr : t_buffer_addr_array;

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

    signal r_state 	: 	t_state_main := init;
    signal r_current_channel : unsigned(1 downto 0) := (others => '0'); -- should depend on NUM_CHANNELS!
    signal r_coeff_count : unsigned(COEFF_A_WIDTH - 1 downto 0) := (others => '0');
    signal r_coeff_ptr : unsigned(COEFF_A_WIDTH - 1 downto 0) := (others => '0');
    signal rate_counter : unsigned(9 downto 0); -- TODO: determine width from output rate

    -- ------------------------------------------------------------------------------
    -- DSP
    -- ------------------------------------------------------------------------------
    signal acc_reset : std_logic := '0';

    signal sample : signed(SAMPLE_WIDTH - 1 downto 0);
    signal coefficient : signed(SAMPLE_WIDTH - 1 downto 0);
    signal mult : signed(SAMPLE_WIDTH * 2 - 1 downto 0);
    signal accumulator : signed(ACCUMULATOR_WIDTH - 1 downto 0);

    -- For testing purposes
    signal r_channel_data_i : signed(SAMPLE_WIDTH - 1 downto 0);

begin

    -- For testing, a it's hard to see inside arrays
    r_channel_data_i <= r_channel_data(to_integer(r_current_channel));

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                if reset_n = '0' then
                    for i in 0 to NUM_CHANNELS - 1 loop
                        r_wr_addr(i) <= to_unsigned(BUFFER_BASE(i) + RD_WR_OFFSET, BUFFER_A_WIDTH);
                        r_channel_dav(i) <= '0';
                        r_channel_data(i) <= to_signed(0, SAMPLE_WIDTH);
                    end loop;
                else
                    -- Latch the channel input sample as soon as it appears
                    for i in 0 to NUM_CHANNELS - 1 loop
                        if channel_clken(i) = '1' and channel_load(i) = '1' and r_channel_dav(i) = '0' then
                            r_channel_dav(i) <= '1';
                            r_channel_data(i) <= channel_in(i);
                        end if;
                    end loop;
                    buffer_we <= '0';
                    -- Buffer writing
                    for i in 0 to NUM_CHANNELS - 1 loop
                        -- build a priority encode to serialize multiple simultaneous buffer writes
                        if r_channel_dav(i) = '1' and all_bits_clear(r_channel_dav(i - 1 downto 0)) then
                            buffer_wr_addr <= r_wr_addr(i);
                            buffer_wr_data <= r_channel_data(i);
                            buffer_we <= '1';
                            r_channel_dav(i) <= '0';
                            -- This assume each buffer is aligned on a 2^BUFFER_WIDTH boundary
                            r_wr_addr(i)(BUFFER_WIDTH(i) - 1 downto 0) <= r_wr_addr(i)(BUFFER_WIDTH(i) - 1 downto 0);
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;




    -- Channel state machine
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                acc_reset <= '0';
                if reset_n = '0' then
                    rate_counter <= (others => '1');
                    r_state <= init;
                    for i in 0 to NUM_CHANNELS - 1 loop
                        k(i) <= to_unsigned(0, COEFF_A_WIDTH);
                        r_rd_addr(i) <= to_unsigned(BUFFER_BASE(i), BUFFER_A_WIDTH);
                    end loop;
                else
                    if rate_counter = 0 then
                        rate_counter <= to_unsigned(OUTPUT_RATE - 1, rate_counter'length);
                    else
                        rate_counter <= rate_counter - 1;
                    end if;
                    case r_state is
                        when idle =>
                            r_current_channel <= (others => '0');
                            if rate_counter = 0 then
                                r_state <= init;
                            end if;
                        when init =>
                            r_coeff_ptr <= k(to_integer(r_current_channel));
                            r_coeff_count <= to_unsigned(FILTER_NTAPS(to_integer(r_current_channel)), COEFF_A_WIDTH);
                            acc_reset <= '1';
                            r_state <= calculate;
                        when calculate =>
                            buffer_rd_addr <= r_rd_addr(to_integer(r_current_channel));
                            coeff_rom_addr <= COEFF_BASE + r_coeff_ptr;
                            r_coeff_ptr  <= r_coeff_ptr + FILTER_L(to_integer(r_current_channel));
                            r_coeff_count <= r_coeff_count - 1;
                            if r_coeff_count = 0 then
                                r_state <= scale;
                            end if;
                        when scale =>
                            r_state <= transfer;
                        when transfer =>
                            k(to_integer(r_current_channel)) <= k(to_integer(r_current_channel)) + FILTER_M;
                            r_current_channel <= r_current_channel + 1;
                            if r_current_channel = to_unsigned(NUM_CHANNELS - 1, r_current_channel'length) then
                                r_state <= idle;
                            else
                                r_state <= init;
                            end if;
                     end case;
                 end if;
            end if;
        end if;
    end process;



    -- DSP

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                if acc_reset = '1' then
                    coefficient <= to_signed(0, coefficient'length);
                    sample <= to_signed(0, sample'length);
                    mult <= to_signed(0, mult'length);
                    accumulator <= to_signed(0, accumulator'length);
                else
                    coefficient <= coeff_rom_data;
                    sample <= buffer_rd_data;
                    mult <= sample * coefficient;
                    accumulator <= accumulator + mult;
                end if;
            end if;
        end if;
    end process;


    -- Output Mixer

    -- Single Port Coefficient ROM
    process(clk)
    begin
        if rising_edge(clk) then
            if clk_en = '1' then
                coeff_rom_data <= coeff_rom(to_integer(coeff_rom_addr));
            end if;
        end if;
    end process;

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


end architecture;
