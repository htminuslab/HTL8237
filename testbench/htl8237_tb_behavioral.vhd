-------------------------------------------------------------------------------
--  HTL8237                                                                  --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : I8237                                                     --
-- Module        : Top Level Testbench                                       --
-- Library       :                                                           --
--                                                                           --
-- Version       : 1.0  20/01/2005   Created HT-LAB                          --
--               : 1.1  09/04/2012   Minor updates for VHDL2008              --
--               : 1.2  30/11/2023   Uploaded to github under MIT license    --                                                           
--                                   checked with Questa/Modelsim 2023.4     --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

USE work.utils.all;

LIBRARY std;
USE std.TEXTIO.all;


ENTITY HTL8237_tb IS
END HTL8237_tb ;


ARCHITECTURE behavioral OF HTL8237_tb IS

   -- Architecture declarations
   signal nCSp0 : std_logic;
   signal nCSp1 : std_logic;
   signal nCSp2 : std_logic;
   signal nCSp3 : std_logic;
   signal ch0_page : std_logic_vector(3 downto 0);
   signal ch1_page : std_logic_vector(3 downto 0);
   signal ch2_page : std_logic_vector(3 downto 0);
   signal ch3_page : std_logic_vector(3 downto 0);
   signal pagem2m : std_logic;

   -- Internal signal declarations
   SIGNAL ABUSH        : std_logic_vector(3 DOWNTO 0);
   SIGNAL IOR          : std_logic;
   SIGNAL IOW          : std_logic;
   SIGNAL MEMR         : std_logic;
   SIGNAL MEMW         : std_logic;
   SIGNAL abus         : std_logic_vector(19 DOWNTO 0);
   SIGNAL adstb        : std_logic;
   SIGNAL aen          : std_logic;
   SIGNAL ale          : std_logic;
   SIGNAL clk          : std_logic;
   SIGNAL dack         : std_logic_vector(3 DOWNTO 0);
   SIGNAL dack2        : std_logic;
   SIGNAL dack_master  : std_logic_vector(3 DOWNTO 0);
   SIGNAL dbus         : std_logic_vector(7 DOWNTO 0);
   SIGNAL dout         : std_logic;
   SIGNAL dout1        : std_logic;
   SIGNAL dreq         : std_logic_vector(3 DOWNTO 0);
   SIGNAL dreq2        : std_logic;
   SIGNAL dreq_master  : std_logic_vector(3 DOWNTO 0);
   SIGNAL eop          : std_logic;
   SIGNAL eop_master   : std_logic;
   SIGNAL hlda         : std_logic;
   SIGNAL hlda_slave   : std_logic;
   SIGNAL hrq          : std_logic;
   SIGNAL hrq_slave    : std_logic;
   SIGNAL mio          : std_logic;
   SIGNAL nCS0         : std_logic       := '1';
   SIGNAL nCS1         : std_logic       := '1';
   SIGNAL nCS2         : std_logic;
   SIGNAL nCS3         : std_logic;
   SIGNAL nCS4         : std_logic;
   SIGNAL page         : std_logic_vector(3 DOWNTO 0);
   SIGNAL patternh     : string(1 TO 13) := "pattern_h.dat";
   SIGNAL patternl     : string(1 TO 13) := "pattern_l.dat";
   SIGNAL porta        : std_logic_vector(7 DOWNTO 0);
   SIGNAL ready        : std_logic;
   SIGNAL ready_master : std_logic;
   SIGNAL reset        : std_logic;
   SIGNAL testcount    : integer;
   SIGNAL testenable   : std_logic;
   SIGNAL testmode     : std_logic_vector(4 DOWNTO 0);

   SIGNAL mw_U_2clk : std_logic;

   -- Component Declarations
   COMPONENT HTL8237
   PORT (
      CLK   : IN     std_logic ;
      CS    : IN     std_logic ;
      DREQ  : IN     std_logic_vector (3 DOWNTO 0);
      HLDA  : IN     std_logic ;
      READY : IN     std_logic ;
      RESET : IN     std_logic ;
      ABUSH : OUT    std_logic_vector (3 DOWNTO 0);
      ADSTB : OUT    std_logic ;
      AEN   : OUT    std_logic ;
      DACK  : OUT    std_logic_vector (3 DOWNTO 0);
      HRQ   : OUT    std_logic ;
      MEMR  : OUT    std_logic ;
      MEMW  : OUT    std_logic ;
      NC    : OUT    std_logic ;
      ABUSL : INOUT  std_logic_vector (3 DOWNTO 0);
      DB    : INOUT  std_logic_vector (7 DOWNTO 0);
      EOP   : INOUT  std_logic ;
      IOR   : INOUT  std_logic ;
      IOW   : INOUT  std_logic 
   );
   END COMPONENT;
   COMPONENT ioblk
   PORT (
      IOR        : IN     std_logic ;
      IOW        : IN     std_logic ;
      MEMR       : IN     std_logic ;
      MEMW       : IN     std_logic ;
      abus       : IN     std_logic_vector (1 DOWNTO 0);
      clk        : IN     std_logic ;
      dack2      : IN     std_logic ;
      nCS3       : IN     std_logic ;
      reset      : IN     std_logic ;
      testenable : IN     std_logic ;
      testmode   : IN     std_logic_vector (4 DOWNTO 0);
      dreq2      : OUT    std_logic ;
      eop        : OUT    std_logic ;
      eop_master : OUT    std_logic ;
      porta      : OUT    std_logic_vector (7 DOWNTO 0);
      ready      : OUT    std_logic ;
      dbus       : INOUT  std_logic_vector (7 DOWNTO 0)
   );
   END COMPONENT;
   COMPONENT sram
   GENERIC (
      clear_on_power_up       : boolean := FALSE;
      download_on_power_up    : boolean := TRUE;
      trace_ram_load          : boolean := TRUE;
      enable_nWE_only_control : boolean := TRUE;
      size                    : INTEGER := 8;
      adr_width               : INTEGER := 3;
      width                   : INTEGER := 8;
      tAA_max                 : TIME    := 20 NS;
      tOHA_min                : TIME    := 3 NS;
      tACE_max                : TIME    := 20 NS;
      tDOE_max                : TIME    := 8 NS;
      tLZOE_min               : TIME    := 0 NS;
      tHZOE_max               : TIME    := 8 NS;
      tLZCE_min               : TIME    := 3 NS;
      tHZCE_max               : TIME    := 10 NS;
      tWC_min                 : TIME    := 20 NS;
      tSCE_min                : TIME    := 18 NS;
      tAW_min                 : TIME    := 15 NS;
      tHA_min                 : TIME    := 0 NS;
      tSA_min                 : TIME    := 0 NS;
      tPWE_min                : TIME    := 13 NS;
      tSD_min                 : TIME    := 10 NS;
      tHD_min                 : TIME    := 0 NS;
      tHZWE_max               : TIME    := 10 NS;
      tLZWE_min               : TIME    := 0 NS
   );
   PORT (
      A                 : IN     std_logic_vector (adr_width-1 DOWNTO 0);
      CE2               : IN     std_logic  := '1';
      download          : IN     boolean    := FALSE;
      download_filename : IN     string     := "loadfname.dat";
      dump              : IN     boolean    := FALSE;
      dump_end          : IN     natural    := size-1;
      dump_filename     : IN     string     := "dumpfname.dat";
      dump_start        : IN     natural    := 0;
      nCE               : IN     std_logic  := '1';
      nOE               : IN     std_logic  := '1';
      nWE               : IN     std_logic  := '1';
      D                 : INOUT  std_logic_vector (width-1 DOWNTO 0)
   );
   END COMPONENT;
   COMPONENT stimulus
   PORT (
      aen        : IN     std_logic ;
      clk        : IN     std_logic ;
      dack       : IN     std_logic_vector (3 DOWNTO 0);
      dreq2      : IN     std_logic ;
      hrq        : IN     std_logic ;
      abus       : OUT    std_logic_vector (19 DOWNTO 0);
      ale        : OUT    std_logic ;
      dack2      : OUT    std_logic ;
      dreq       : OUT    std_logic_vector (3 DOWNTO 0);
      mio        : OUT    std_logic ;
      reset      : OUT    std_logic ;
      testcount  : OUT    integer ;
      testenable : OUT    std_logic ;
      testmode   : OUT    std_logic_vector (4 DOWNTO 0);
      IOR        : INOUT  std_logic ;
      IOW        : INOUT  std_logic ;
      MEMR       : INOUT  std_logic ;
      MEMW       : INOUT  std_logic ;
      dbus       : INOUT  std_logic_vector (7 DOWNTO 0);
      eop        : INOUT  std_logic ;
      hlda       : BUFFER std_logic 
   );
   END COMPONENT;

BEGIN
   -- Architecture concurrent statements
   -- After Reset all DREQ signals are initialised active high
   dreq_master(0) <= hrq_slave;
   dreq_master(3 downto 1) <= (others =>'0');
   
   -- After Reset all DACK signals are initialised to active low
   hlda_slave <= dack_master(0);
   
   ready_master <= '1';
   eop_master   <= 'H';                                      

   -- Simple 82C82 Type Latch
   process (aen,adstb,dbus)
         begin  
             if aen='0' then
                abus(15 downto 8) <= (others => 'Z');
             elsif adstb='1' then
                abus(15 downto 8) <= dbus;
             end if;
   end process;  
                                        
   abus(7 downto 4) <= ABUSH;
   abus(19 downto 16) <= page when aen='1' else "ZZZZ";

   ---------------------------------------------------------------------------
   -- Bottom 128Kbyte 
   -- 00000-1FFFF
   ---------------------------------------------------------------------------
   nCS0 <= '0' when ((abus(19 downto 17)="000") AND mio='1') else '1';
   
   ---------------------------------------------------------------------------
   -- 128Kbyte (512K-640K)
   -- 80000-9FFFF
   ---------------------------------------------------------------------------
   nCS1 <= '0' when ((abus(19 downto 17)="100") AND mio='1') else '1';
   
   ---------------------------------------------------------------------------
   -- 0x00-0x1f DMA Controller #1 (Channels 0, 1, 2 and 3)
   -- 0xc0-0xdf DMA Controller #2 (Channels 4, 5, 6 and 7)
   ---------------------------------------------------------------------------
   nCS2 <= '0' when ((abus(15 downto 5)="00000000000") AND mio='0') else '1';
   nCS4 <= '0' when ((abus(15 downto 5)="00000000110") AND mio='0') else '1';
   
   ---------------------------------------------------------------------------
   -- Byte Peripheral
   -- 0x2F8-0x2F9
   ---------------------------------------------------------------------------
   nCS3 <= '0' when ((abus(15 downto 1)="000000101111100") AND mio='0') else '1';
   
   ---------------------------------------------------------------------------
   -- DMA Page Registers
   -- 0x87    r/w    Channel 0 Low byte (23-16) page Register
   -- 0x83    r/w    Channel 1 Low byte (23-16) page Register
   -- 0x81    r/w    Channel 2 Low byte (23-16) page Register
   -- 0x82    r/w    Channel 3 Low byte (23-16) page Register                              
   ---------------------------------------------------------------------------
   nCSp0 <= '0' when ((abus(15 downto 0)=X"0087") AND mio='0') else '1';
   nCSp1 <= '0' when ((abus(15 downto 0)=X"0083") AND mio='0') else '1';
   nCSp2 <= '0' when ((abus(15 downto 0)=X"0081") AND mio='0') else '1';
   nCSp3 <= '0' when ((abus(15 downto 0)=X"0082") AND mio='0') else '1';
   
   ---------------------------------------------------------------------------
   -- 4 bits page registers
   ---------------------------------------------------------------------------
   process(reset,clk) 
       begin
        if reset='1' then
            ch0_page <= (others => '0'); 
            ch1_page <= (others => '0'); 
            ch2_page <= (others => '0'); 
            ch3_page <= (others => '0'); 
           elsif falling_edge(clk) then
               if iow='0' then 
                   if nCSp0='0' then
                      ch0_page <= dbus(3 downto 0);   
                   end if;
                   if nCSp1='0' then
                      ch1_page <= dbus(3 downto 0);   
                   end if;
                   if nCSp2='0' then
                      ch2_page <= dbus(3 downto 0);   
                   end if;
                   if nCSp3='0' then
                      ch3_page <= dbus(3 downto 0);   
                   end if;
               end if;
         end if;
   end process;
   
   ---------------------------------------------------------------------------
   -- Select Active Page (only 4 bits used)
   ---------------------------------------------------------------------------
   process (reset,clk)
       begin
        if (reset='1') then
            page<=(others =>'0');           
           elsif rising_edge(clk) then
            if aen='0' then
                pagem2m<='0';
            elsif adstb='1' then
                   pagem2m<=not pagem2m;                        -- Swap pages after second adstb
               end if;
            if adstb='1' then 
                case dack is 
                   when "0001" => page <= ch0_page;
                   when "0010" => page <= ch1_page;
                   when "0100" => page <= ch2_page;
                   when "1000" => page <= ch3_page;
                   when "1110" => page <= ch0_page;
                   when "1101" => page <= ch1_page;
                   when "1011" => page <= ch2_page;
                   when "0111" => page <= ch3_page;            
                   when others =>                           -- Select CH0 for mem2mem, no DACK
                      if pagem2m='0' then 
                          page <= ch0_page; 
                      else
                          page <= ch1_page;
                      end if;
                end case;
            end if;
           end if;
   end process;

   u_2clk_proc: PROCESS
   BEGIN
      LOOP
         mw_U_2clk <= '0', '1' AFTER 25.00 ns;
         WAIT FOR 50.00 ns;
      END LOOP;
      WAIT;
   END PROCESS u_2clk_proc;
   clk <= mw_U_2clk;

   dout1 <= '1';
   dout <= '1';

   -- Instance port mappings.
   DUT : HTL8237
      PORT MAP (
         CLK   => clk,
         CS    => nCS2,
         DREQ  => dreq,
         HLDA  => hlda_slave,
         READY => ready,
         RESET => reset,
         ABUSH => ABUSH,
         ADSTB => adstb,
         AEN   => aen,
         DACK  => dack,
         HRQ   => hrq_slave,
         MEMR  => MEMR,
         MEMW  => MEMW,
         NC    => OPEN,
         ABUSL => abus(3 DOWNTO 0),
         DB    => dbus,
         EOP   => eop,
         IOR   => IOR,
         IOW   => IOW
      );
   MASTER : HTL8237
      PORT MAP (
         CLK   => clk,
         CS    => nCS4,
         DREQ  => dreq_master,
         HLDA  => hlda,
         READY => ready_master,
         RESET => reset,
         ABUSH => OPEN,
         ADSTB => OPEN,
         AEN   => OPEN,
         DACK  => dack_master,
         HRQ   => hrq,
         MEMR  => OPEN,
         MEMW  => OPEN,
         NC    => OPEN,
         ABUSL => abus(3 DOWNTO 0),
         DB    => dbus,
         EOP   => eop_master,
         IOR   => IOR,
         IOW   => IOW
      );
   IO0 : ioblk
      PORT MAP (
         IOR        => IOR,
         IOW        => IOW,
         MEMR       => MEMR,
         MEMW       => MEMW,
         abus       => abus(1 DOWNTO 0),
         clk        => clk,
         dack2      => dack2,
         nCS3       => nCS3,
         reset      => reset,
         testenable => testenable,
         testmode   => testmode,
         dreq2      => dreq2,
         eop        => eop,
         eop_master => eop_master,
         porta      => porta,
         ready      => ready,
         dbus       => dbus
      );
   MEM0 : sram
      GENERIC MAP (
         clear_on_power_up       => TRUE,
         download_on_power_up    => TRUE,
         trace_ram_load          => FALSE,
         enable_nWE_only_control => TRUE,
         size                    => 131072,
         adr_width               => 17,
         width                   => 8,
         tAA_max                 => 20 NS,
         tOHA_min                => 3 NS,
         tACE_max                => 20 NS,
         tDOE_max                => 8 NS,
         tLZOE_min               => 0 NS,
         tHZOE_max               => 8 NS,
         tLZCE_min               => 3 NS,
         tHZCE_max               => 10 NS,
         tWC_min                 => 20 NS,
         tSCE_min                => 18 NS,
         tAW_min                 => 15 NS,
         tHA_min                 => 0 NS,
         tSA_min                 => 0 NS,
         tPWE_min                => 13 NS,
         tSD_min                 => 10 NS,
         tHD_min                 => 0 NS,
         tHZWE_max               => 10 NS,
         tLZWE_min               => 0 NS
      )
      PORT MAP (
         download_filename => patternl,
         nCE               => nCS0,
         nOE               => MEMR,
         nWE               => MEMW,
         A                 => abus(16 DOWNTO 0),
         D                 => dbus,
         CE2               => dout1,
         download          => OPEN,
         dump              => OPEN,
         dump_start        => OPEN,
         dump_end          => OPEN,
         dump_filename     => OPEN
      );
   MEM1 : sram
      GENERIC MAP (
         clear_on_power_up       => FALSE,
         download_on_power_up    => FALSE,
         trace_ram_load          => FALSE,
         enable_nWE_only_control => TRUE,
         size                    => 131072,
         adr_width               => 17,
         width                   => 8,
         tAA_max                 => 20 NS,
         tOHA_min                => 3 NS,
         tACE_max                => 20 NS,
         tDOE_max                => 8 NS,
         tLZOE_min               => 0 NS,
         tHZOE_max               => 8 NS,
         tLZCE_min               => 3 NS,
         tHZCE_max               => 10 NS,
         tWC_min                 => 20 NS,
         tSCE_min                => 18 NS,
         tAW_min                 => 15 NS,
         tHA_min                 => 0 NS,
         tSA_min                 => 0 NS,
         tPWE_min                => 13 NS,
         tSD_min                 => 10 NS,
         tHD_min                 => 0 NS,
         tHZWE_max               => 10 NS,
         tLZWE_min               => 0 NS
      )
      PORT MAP (
         download_filename => patternh,
         nCE               => nCS1,
         nOE               => MEMR,
         nWE               => MEMW,
         A                 => abus(16 DOWNTO 0),
         D                 => dbus,
         CE2               => dout,
         download          => OPEN,
         dump              => OPEN,
         dump_start        => OPEN,
         dump_end          => OPEN,
         dump_filename     => OPEN
      );
   STIM : stimulus
      PORT MAP (
         aen        => aen,
         clk        => clk,
         dack       => dack,
         dreq2      => dreq2,
         hrq        => hrq,
         abus       => abus,
         ale        => ale,
         dack2      => dack2,
         dreq       => dreq,
         mio        => mio,
         reset      => reset,
         testcount  => testcount,
         testenable => testenable,
         testmode   => testmode,
         IOR        => IOR,
         IOW        => IOW,
         MEMR       => MEMR,
         MEMW       => MEMW,
         dbus       => dbus,
         eop        => eop,
         hlda       => hlda
      );

END behavioral;
