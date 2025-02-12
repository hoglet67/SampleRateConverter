-- Simple I2S Interface
--
-- Copright (c) 2025 David Banks
--
-- Based on work in MISTeryNano
--
-- Copyright (c) 2024 Till Harbaum
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

entity i2s_simple is
    generic (
        CLOCKSPEED : natural;
        SAMPLERATE : natural;
        ATTENUATE  : natural := 0
    );
    port (
        -- Clock/Reset
        clock      : in  std_logic;
        reset_n    : in  std_logic;

        -- Parallel Audio In (signed)
        audio_l    : in  std_logic_vector(15 downto 0);
        audio_r    : in  std_logic_vector(15 downto 0);

        -- I2S Audio Out
        i2s_bclk   : out std_logic;
        i2s_lrclk  : out std_logic;
        i2s_din    : out std_logic;
        pa_en      : out std_logic
    );
end entity;

architecture rtl of i2s_simple is

    -- Use 32-bit mode of the MAX98357A for full 105dB dynamic range
    constant MAXCOUNT : natural := CLOCKSPEED / (SAMPLERATE * 64) / 2 - 1;

    signal clk_audio     : std_logic := '0';
    signal aclk_cnt      : unsigned(7 downto 0);
    signal audio_mixed   : std_logic_vector(16 downto 0);
    signal audio         : std_logic_vector(31 downto 0);
    signal audio_bit_cnt : unsigned(5 downto 0);

begin

    pa_en <= reset_n; -- enable amplifier

    -- mix both stereo channels into one mono channel
    -- audio-1 and audio-r are 16-bit signed; result is a 17-bit signed so overflow is impossible
    audio_mixed <= std_logic_vector(unsigned(audio_l(15) & audio_l) + unsigned(audio_r(15) & audio_r));

    process(clock)
    begin
        if rising_edge(clock) then
            if (aclk_cnt < MAXCOUNT) then
                aclk_cnt <= aclk_cnt + 1;
            else
                aclk_cnt <= (others => '0');
                clk_audio <=  not clk_audio;
                -- Data must change on the falling edge of clk_audio
                if clk_audio = '1' then
                    if reset_n = '0' then
                        audio_bit_cnt <= (others => '0');
                    else
                        audio_bit_cnt <= audio_bit_cnt + 1;
                    end if;
                    -- latch data so it's stable during transmission
                    if audio_bit_cnt = "111111" then
                        -- convert to 17-bit to 32-bit, attenuated by shift of ATTENUATE of bits
                        -- audio_mixed:    SBBBBBBBBBBBBBBBB
                        -- audio:       SSSSBBBBBBBBBBBBBBBB000000000000
                        --                 ^^^^^^^^^^^^^^^^^ (audio_mixed)
                        if (ATTENUATE = 0) then
                            audio <= audio_mixed & (14 downto 0 => '0');
                        else
                            audio <= (31 downto 32-ATTENUATE => audio_mixed(16)) & audio_mixed & (14-ATTENUATE downto 0 => '0');
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- generate i2s signals
    i2s_bclk  <= clk_audio;
    i2s_lrclk <= '0' when reset_n = '0' else audio_bit_cnt(5);
    i2s_din   <= '0' when reset_n = '0' else audio(to_integer(31 - unsigned(audio_bit_cnt(4 downto 0))));

end architecture;
