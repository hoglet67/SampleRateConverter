library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rPLL is
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
end rPLL;

architecture rtl of rPLL is
begin
    CLKOUTD <= CLKIN;

end rtl;
