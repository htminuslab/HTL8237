-------------------------------------------------------------------------------
--  HTL8237                                                                  --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : I8237                                                     --
-- Module        : Package File                                              --
-- Library       :                                                           --
--                                                                           --
-- Version       : 1.0  20/01/2005   Created HT-LAB                          --
--               : 1.1  20/11/2023   Uploaded to github under MIT license    --                      
--                                   checked with Questa/Modelsim 2023.4     --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE pack8237 IS

    constant READ_STATUS_REG_C    : std_logic_vector(3 downto 0):="1000";
    constant WRITE_COMMAND_REG_C  : std_logic_vector(3 downto 0):="1000";
    constant READ_REQUEST_REG_C   : std_logic_vector(3 downto 0):="1001";
    constant WRITE_REQUEST_REG_C  : std_logic_vector(3 downto 0):="1001";
    constant READ_COMMAND_REG_C   : std_logic_vector(3 downto 0):="1010";
    constant WRITE_SMASK_BIT_C    : std_logic_vector(3 downto 0):="1010";
    constant READ_MODE_REG_C      : std_logic_vector(3 downto 0):="1011";
    constant WRITE_MODE_REG_C     : std_logic_vector(3 downto 0):="1011";
    constant SET_FIRSTLASTFF_C    : std_logic_vector(3 downto 0):="1100";
    constant CLEAR_FIRSTLASTFF_C  : std_logic_vector(3 downto 0):="1100";
    constant READ_TEMP_REGISTER_C : std_logic_vector(3 downto 0):="1101";
    constant MASTER_CLEAR_C       : std_logic_vector(3 downto 0):="1101";
    constant CLEAR_MODE_REG_CNT_C : std_logic_vector(3 downto 0):="1110";
    constant CLEAR_MASK_REGISTER_C: std_logic_vector(3 downto 0):="1110";
    constant READ_ALL_MASK_BITS_C : std_logic_vector(3 downto 0):="1111";
    constant WRITE_ALL_MASK_BITS_C: std_logic_vector(3 downto 0):="1111";

END pack8237;
