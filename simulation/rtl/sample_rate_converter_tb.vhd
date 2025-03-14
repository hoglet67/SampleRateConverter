library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sample_rate_converter_pkg.all;

entity sample_rate_converter_tb is
    generic (
        NUM_CHANNELS : integer := 4;
        SAMPLE_WIDTH : integer := 18;
        OUTPUT_WIDTH : integer := 20;
        TEST_TONE    : integer := 525
    );
end sample_rate_converter_tb;

architecture Behavioral of sample_rate_converter_tb is

    signal clk48           : std_logic := '0';
    signal reset_n         : std_logic := '0';
    signal div8_counter    : unsigned(2 downto 0) := (others => '0');
    signal div6_counter    : unsigned(2 downto 0) := (others => '0'); -- for 1MHz
    signal div24_counter   : unsigned(4 downto 0) := (others => '0'); -- for 250KHz
    signal div128_counter  : unsigned(6 downto 0) := (others => '0'); -- for 46.875KHZ
    signal clk6_en         : std_logic := '0';
    signal sid_counter     : unsigned(11 downto 0) := (others => '0');
    signal psg_counter     : unsigned(11 downto 0) := (others => '0');
    signal m5k_counter     : unsigned(11 downto 0) := (others => '0');

    -- Step input of from 0 to +/- 95% full scale value
    constant step          : integer := (2 ** (SAMPLE_WIDTH - 1)) * 95 / 100;

    signal sid_audio       : signed(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
    signal sid_audio_load  : std_logic := '0';
    signal psg_audio       : signed(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
    signal psg_audio_load  : std_logic := '0';
    signal m5k_audio_l     : signed(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
    signal m5k_audio_r     : signed(SAMPLE_WIDTH - 1 downto 0) := (others => '0');
    signal m5k_audio_load  : std_logic := '0';
    signal mixer_l         : signed(OUTPUT_WIDTH - 1 downto 0);
    signal mixer_r         : signed(OUTPUT_WIDTH - 1 downto 0);
    signal mixer_strobe    : std_logic := '0';

    signal channel_in      : t_sample_array(0 to NUM_CHANNELS - 1);
    signal channel_clken   : std_logic_vector(NUM_CHANNELS - 1 downto 0);
    signal channel_load    : std_logic_vector(NUM_CHANNELS - 1 downto 0);

begin

    clk48 <= not clk48 after 10.333 ns;

    process(clk48)
    begin
        if rising_edge(clk48) then
            if div8_counter = 7 then
                div8_counter <= (others => '0');
                clk6_en <= '1';
            else
                div8_counter <= div8_counter + 1;
                clk6_en <= '0';
            end if;
            if clk6_en = '1' then
                if div6_counter = 5 then
                    div6_counter <= (others => '0');
                    sid_audio_load <= '1';
                    sid_counter <= sid_counter + 1;
                else
                    div6_counter <= div6_counter + 1;
                    sid_audio_load <= '0';
                end if;
                if div24_counter = 23 then
                    div24_counter <= (others => '0');
                    psg_audio_load <= '1';
                    psg_counter <= psg_counter + 1;
                else
                    div24_counter <= div24_counter + 1;
                    psg_audio_load <= '0';
                end if;
                if div128_counter = 127 then
                    div128_counter <= (others => '0');
                    m5k_audio_load <= '1';
                    m5k_counter <= m5k_counter + 1;
                else
                    div128_counter <= div128_counter + 1;
                    m5k_audio_load <= '0';
                end if;
                if m5k_counter = 2 then
                    reset_n <= '1';
                end if;
                -- if sid_audio_load <= '1' then
                --     if sid_counter = 1000000 / TEST_TONE / 2 - 1 then
                --         sid_audio <= to_signed(step, SAMPLE_WIDTH);
                --     elsif sid_counter = 1000000 / TEST_TONE - 1 then
                --         sid_audio <= to_signed(-step, SAMPLE_WIDTH);
                --         sid_counter <= (others => '0');
                --     end if;
                -- end if;
                if psg_audio_load <= '1' then
                    if psg_counter = 250000 / TEST_TONE / 2 -1 then
                        psg_audio <= to_signed(step, SAMPLE_WIDTH);
                    elsif psg_counter = 250000 / TEST_TONE - 1 then
                        psg_audio <= to_signed(-step, SAMPLE_WIDTH);
                        psg_counter <= (others => '0');
                    end if;
                end if;
                -- if m5k_audio_load <= '1' then
                --     if m5k_counter = 46875 / TEST_TONE / 2 -1 then
                --         m5k_audio_l <= to_signed(step, SAMPLE_WIDTH);
                --         m5k_audio_r <= to_signed(step, SAMPLE_WIDTH);
                --     elsif m5k_counter = 46875 / TEST_TONE - 1 then
                --         m5k_audio_l <= to_signed(-step, SAMPLE_WIDTH);
                --         m5k_audio_r <= to_signed(-step, SAMPLE_WIDTH);
                --         m5k_counter <= (others => '0');
                --     end if;
                -- end if;
            end if;
        end if;
    end process;

    process(clk48)
    begin
        if rising_edge(clk48) then
            if mixer_strobe = '1' then
                report
                    integer'image(to_integer(mixer_l)) & " " &
                    integer'image(to_integer(mixer_r));
            end if;
        end if;
    end process;


    -- Channels are:
    -- 0: SID
    -- 1: SN76489
    -- 2: Music 5000 L
    -- 3: Music 5000 R

    channel_clken <= clk6_en & clk6_en & clk6_en & clk6_en;
    channel_load  <= m5k_audio_load & m5k_audio_load & psg_audio_load & sid_audio_load;
    channel_in    <= (sid_audio, psg_audio, m5k_audio_l, m5k_audio_r);

    sample_rate_converter_inst : entity work.sample_rate_converter
        generic map (
            NUM_CHANNELS      => NUM_CHANNELS,
            OUTPUT_RATE       => 1000,           -- 48KHz
            OUTPUT_WIDTH      => 20,             -- 20 bits
            FILTER_NTAPS      => 3840,
            FILTER_L          => (6, 24, 128, 128),
            FILTER_M          => 125,
            CHANNEL_TYPE      => (mono, mono, left_channel, right_channel),
            BUFFER_A_WIDTH    => 10,             -- 1K Words
            COEFF_A_WIDTH     => 11,             -- 2K Words
            ACCUMULATOR_WIDTH => 54,
--            BUFFER_SIZE       => (700, 175, 40, 40)
            BUFFER_SIZE       => (704, 192, 64, 64)
            )
        port map (
            clk               => clk48,
            reset_n           => reset_n,
            volume            => to_unsigned(64, 8),
            channel_clken     => channel_clken,
            channel_load      => channel_load,
            channel_in        => channel_in,
            mixer_strobe      => mixer_strobe,
            mixer_l           => mixer_l,
            mixer_r           => mixer_r
            );

end Behavioral;
