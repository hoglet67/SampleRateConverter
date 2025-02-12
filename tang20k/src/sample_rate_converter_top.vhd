library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sample_rate_converter_pkg.all;

entity sample_rate_converter_top is
    generic (
        sample_width : integer := 18;
        output_width : integer := 20;
        test_tone    : integer := 525
        );
    port (
        sys_clk         : in    std_logic;
        btn1            : in    std_logic;
        -- I2S Audio
        i2s_bclk        : out   std_logic;
        i2s_lrclk       : out   std_logic;
        i2s_din         : out   std_logic;
        pa_en           : out   std_logic;
        -- S/PDIF Audio
        audio_spdif     : out   std_logic;
        -- PCM Audio
        audio_load      : out   std_logic;
        audio_pcm       : out   std_logic_vector(15 downto 0)
        );
end sample_rate_converter_top;

architecture rtl of sample_rate_converter_top is

    component rPLL
        generic (
            FCLKIN: in string := "100.0";
            DEVICE: in string := "GW1N-4";
            DYN_IDIV_SEL: in string := "false";
            IDIV_SEL: in integer := 0;
            DYN_FBDIV_SEL: in string := "false";
            FBDIV_SEL: in integer := 0;
            DYN_ODIV_SEL: in string := "false";
            ODIV_SEL: in integer := 8;
            PSDA_SEL: in string := "0000";
            DYN_DA_EN: in string := "false";
            DUTYDA_SEL: in string := "1000";
            CLKOUT_FT_DIR: in bit := '1';
            CLKOUTP_FT_DIR: in bit := '1';
            CLKOUT_DLY_STEP: in integer := 0;
            CLKOUTP_DLY_STEP: in integer := 0;
            CLKOUTD3_SRC: in string := "CLKOUT";
            CLKFB_SEL: in string := "internal";
            CLKOUT_BYPASS: in string := "false";
            CLKOUTP_BYPASS: in string := "false";
            CLKOUTD_BYPASS: in string := "false";
            CLKOUTD_SRC: in string := "CLKOUT";
            DYN_SDIV_SEL: in integer := 2
            );
        port (
            CLKOUT: out std_logic;
            LOCK: out std_logic;
            CLKOUTP: out std_logic;
            CLKOUTD: out std_logic;
            CLKOUTD3: out std_logic;
            RESET: in std_logic;
            RESET_P: in std_logic;
            CLKIN: in std_logic;
            CLKFB: in std_logic;
            FBDSEL: in std_logic_vector(5 downto 0);
            IDSEL: in std_logic_vector(5 downto 0);
            ODSEL: in std_logic_vector(5 downto 0);
            PSDA: in std_logic_vector(3 downto 0);
            DUTYDA: in std_logic_vector(3 downto 0);
            FDLY: in std_logic_vector(3 downto 0)
            );
    end component;

    signal clk48           : std_logic;
    signal powerup_reset_n : std_logic;
    signal reset_counter   : unsigned(10 downto 0) := (others => '0');
    signal div8_counter    : unsigned(2 downto 0) := (others => '0');
    signal div24_counter   : unsigned(4 downto 0) := (others => '0'); -- for 250KHz
    signal clk6_en         : std_logic := '0';
    signal psg_counter     : unsigned(11 downto 0) := (others => '0');
    signal psg_audio       : signed(sample_width - 1 downto 0) := (others => '0');

    -- Step input of from 0 to +/- 25% full scale value
    constant step          : integer := (2 ** (sample_width - 1)) * 10 / 100;

    signal psg_audio_load  : std_logic := '0';
    signal mixer_l         : signed(output_width - 1 downto 0);
    signal mixer_r         : signed(output_width - 1 downto 0);
    signal mixer_load      : std_logic := '0';

    signal channel_in      : t_sample_array;
    signal channel_clken   : std_logic_vector(NUM_CHANNELS - 1 downto 0);
    signal channel_load    : std_logic_vector(NUM_CHANNELS - 1 downto 0);

    signal audio_pcm_int   : std_logic_vector(15 downto 0);

    signal test           : signed(17 downto 0) := to_signed(8000, 18);
    signal test_ctr       : unsigned(15 downto 0) := (others => '0');

begin

    pll1 : rPLL
        generic map (
            FCLKIN => "27",
            DEVICE => "GW2AR-18C",
            IDIV_SEL => 8,
            FBDIV_SEL => 31,
            ODIV_SEL => 8,
            DYN_SDIV_SEL => 2,
            PSDA_SEL => "1000"          -- 180 degree phase shift
        )
        port map (
            CLKIN    => sys_clk,
            CLKOUT   => open,
            CLKOUTP  => open,
            CLKOUTD  => clk48,
            CLKOUTD3 => open,
            LOCK     => open,
            RESET    => '0',
            RESET_P  => '0',
            CLKFB    => '0',
            FBDSEL   => (others => '0'),
            IDSEL    => (others => '0'),
            ODSEL    => (others => '0'),
            PSDA     => (others => '0'),
            DUTYDA   => (others => '0'),
            FDLY     => (others => '0')
        );

    reset_gen : process(clk48)
    begin
        if rising_edge(clk48) then
            if (btn1 = '1') then
                reset_counter <= (others => '0');
            elsif (reset_counter(reset_counter'high) = '0') then
                reset_counter <= reset_counter + 1;
            end if;
            powerup_reset_n <= reset_counter(reset_counter'high);
        end if;
    end process;


    process(clk48)
    begin
        if rising_edge(clk48) then
            if clk6_en = '1' then
                if test_ctr = 6000000 / 525 / 2 - 1 then
                    test <= -test;
                    test_ctr <= (others => '0');
                else
                    test_ctr <= test_ctr + 1;
                end if;
            end if;
        end if;
    end process;

    process(clk48)
    begin
        if rising_edge(clk48) then
            if div8_counter = 7 then
                div8_counter <= (others => '0');
                clk6_en <= '1';
            else
                div8_counter <= div8_counter + to_unsigned(1, div8_counter'length);
                clk6_en <= '0';
            end if;
            if clk6_en = '1' then
                if div24_counter = 23 then
                    div24_counter <= (others => '0');
                    psg_audio_load <= '1';
                    psg_counter <= psg_counter + 1;
                else
                    div24_counter <= div24_counter + 1;
                    psg_audio_load <= '0';
                end if;
                if psg_audio_load <= '1' then
                    if psg_counter = 250000 / test_tone / 2 -1 then
                        psg_audio <= to_signed(step, sample_width);
                    elsif psg_counter = 250000 / test_tone - 1 then
                        psg_audio <= to_signed(-step, sample_width);
                        psg_counter <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;

    channel_clken <= clk6_en & clk6_en & clk6_en & clk6_en;
    channel_load  <= "00" & psg_audio_load & "0";
    channel_in    <= (
        to_signed(0, sample_width), test, to_signed(0, sample_width), to_signed(0, sample_width));

    sample_rate_converter_inst : entity work.sample_rate_converter
        generic map (
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
            reset_n           => powerup_reset_n,
            volume            => to_unsigned(64, 8),
            channel_clken     => channel_clken,
            channel_load      => channel_load,
            channel_in        => channel_in,
            mixer_load        => mixer_load,
            mixer_l           => mixer_l,
            mixer_r           => mixer_r
            );

        i2s : entity work.i2s_simple
            generic map (
                CLOCKSPEED => 48000000,
                SAMPLERATE => 48000      -- Sample Rate of resampler
                )
            port map (
                clock      => clk48,
                reset_n    => powerup_reset_n,
                audio_l    => audio_pcm_int,
                audio_r    => audio_pcm_int,
                i2s_lrclk  => i2s_lrclk,
                i2s_bclk   => i2s_bclk,
                i2s_din    => i2s_din,
                pa_en      => pa_en
                );

    audio_load <= mixer_load;
    audio_pcm_int <= std_logic_vector(mixer_l(19 downto 4));
    audio_pcm <= audio_pcm_int;

end rtl;
