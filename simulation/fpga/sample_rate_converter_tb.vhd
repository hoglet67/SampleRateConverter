library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sample_rate_converter_tb is
end sample_rate_converter_tb;

architecture Behavioral of sample_rate_converter_tb is

    signal clk48 : std_logic := '0';
    signal audio_load : std_logic;
    signal audio_spdif : std_logic;
    signal audio_pcm : std_logic_vector(15 downto 0);

begin

    clk48 <= not clk48 after 10.333 ns;

    top_inst : entity work.sample_rate_converter_top
        port map (
            sys_clk         => clk48,
            btn1            => '0',
            audio_spdif     => audio_spdif,
            audio_load      => audio_load,
            audio_pcm       => audio_pcm
            );

    process(clk48)
    begin
        if rising_edge(clk48) then
            if audio_load = '1' then
                report
                    integer'image(to_integer(signed(audio_pcm)));
            end if;
        end if;
    end process;

end Behavioral;
