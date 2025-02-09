library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sample_rate_converter_pkg.all;

entity sample_rate_converter_tb is
    generic (
        dacwidth : integer := 18
    );
end sample_rate_converter_tb;

architecture Behavioral of sample_rate_converter_tb is

    signal clk48           : std_logic := '0';
    signal reset_n         : std_logic := '0';
    signal div8_counter    : unsigned(2 downto 0) := (others => '0');
    signal div128_counter  : unsigned(6 downto 0) := (others => '0');
    signal clk6_en         : std_logic := '0';
    signal counter         : unsigned(11 downto 0) := (others => '0');

    -- Step input of from 0 to +/- 90% full scale value
    constant step          : integer := (2 ** (dacwidth - 1)) * 90 / 100;

    signal audio_l         : signed(dacwidth - 1 downto 0) := (others => '0');
    signal audio_r         : signed(dacwidth - 1 downto 0) := (others => '0');
    signal audio_load      : std_logic := '0';
    signal mixer_left      : signed(dacwidth - 1 downto 0);
    signal mixer_right     : signed(dacwidth - 1 downto 0);
    signal mixer_load      : std_logic := '0';

    signal channel_in      : t_sample_array;
    signal channel_clken   : std_logic_vector(NUM_CHANNELS - 1 downto 0);
    signal channel_load    : std_logic_vector(NUM_CHANNELS - 1 downto 0);

begin

    clk48 <= not clk48 after 10.333 ns;

    process(clk48)
    begin
        if rising_edge(clk48) then
            clk6_en <= '0';
            div8_counter <= div8_counter + 1;
            if div8_counter = 0 then
                clk6_en <= '1';
            end if;
            if clk6_en = '1' then
                audio_load <= '0';
                div128_counter <= div128_counter + 1;
                if div128_counter = 0 then
                    audio_load <= '1';
                    if counter < x"FFF" then
                        counter <= counter + 1;
                    end if;
                end if;
                if audio_load <= '1' then
                    if counter = 2 then
                        reset_n <= '1';
                    end if;
                    if counter = 4 then
                        audio_l <= to_signed(step, dacwidth);
                        audio_r <= to_signed(-step, dacwidth);
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(clk48)
    begin
        if rising_edge(clk48) then
            if mixer_load = '1' then
                report
                    integer'image(to_integer(mixer_left)) & " " &
                    integer'image(to_integer(mixer_right));
            end if;
        end if;
    end process;


    -- Channels are:
    -- 0: SID
    -- 1: SN76489
    -- 2: Music 5000 L
    -- 3: Music 5000 R

    channel_clken <= clk6_en & clk6_en & clk6_en & clk6_en;
    channel_load  <= audio_load & audio_load & "00";
    channel_in    <= ( to_signed(0, dacwidth), to_signed(0, dacwidth), audio_l, audio_r);

    sample_rate_converter_inst : entity work.sample_rate_converter
        generic map (
            COEFF_BASE        => 1344,
            OUTPUT_RATE       => 1000,           -- 48KHz
            FILTER_L          => (6, 24, 128, 128),
            FILTER_M          => 125,
            FILTER_NTAPS      => (448, 112, 21, 21),
            BUFFER_A_WIDTH    => 10,             -- 1K Words
            COEFF_A_WIDTH     => 11,             -- 2K Words
            ACCUMULATOR_WIDTH => 54,
            BUFFER_WIDTH      => (9, 7, 5, 5)    -- powers of two
            )
        port map (
            clk            => clk48,
            reset_n        => reset_n,
            channel_clken  => channel_clken,
            channel_load   => channel_load,
            channel_in     => channel_in,
            mixer_load     => mixer_load,
            mixer_left     => mixer_left,
            mixer_right    => mixer_right
            );

end Behavioral;
