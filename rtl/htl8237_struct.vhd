-------------------------------------------------------------------------------
--  HTL8237                                                                  --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : I8237                                                     --
-- Module        : Top Level                                                 --
-- Library       :                                                           --
--                                                                           --
-- Version       : 1.0  20/01/2005   Created HT-LAB                          --
--               : 1.1  30/11/2023   Uploaded to github under MIT license    -- 
--                                   checked with Questa/Modelsim 2023.4     --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.NUMERIC_STD.all;

USE work.pack8237.all;

ENTITY HTL8237 IS
   PORT( 
      CLK   : IN     std_logic;
      CS    : IN     std_logic;
      DREQ  : IN     std_logic_vector (3 DOWNTO 0);
      HLDA  : IN     std_logic;
      READY : IN     std_logic;
      RESET : IN     std_logic;
      ABUSH : OUT    std_logic_vector (3 DOWNTO 0);
      ADSTB : OUT    std_logic;
      AEN   : OUT    std_logic;
      DACK  : OUT    std_logic_vector (3 DOWNTO 0);
      HRQ   : OUT    std_logic;
      MEMR  : OUT    std_logic;
      MEMW  : OUT    std_logic;
      NC    : OUT    std_logic;
      ABUSL : INOUT  std_logic_vector (3 DOWNTO 0);
      DB    : INOUT  std_logic_vector (7 DOWNTO 0);
      EOP   : INOUT  std_logic;
      IOR   : INOUT  std_logic;
      IOW   : INOUT  std_logic
   );
END HTL8237 ;

ARCHITECTURE struct OF HTL8237 IS

   -- Internal signal declarations
   SIGNAL abush_out : std_logic_vector(3 DOWNTO 0);
   SIGNAL abusl_in  : std_logic_vector(3 DOWNTO 0);
   SIGNAL abusl_out : std_logic_vector(3 DOWNTO 0);
   SIGNAL aen_s     : std_logic;
   SIGNAL dbus_in   : std_logic_vector(7 DOWNTO 0);
   SIGNAL dbus_out  : std_logic_vector(7 DOWNTO 0);
   SIGNAL eop_in    : std_logic;
   SIGNAL eop_out   : std_logic;
   SIGNAL iorn_in   : std_logic;
   SIGNAL iorn_out  : std_logic;
   SIGNAL iown_in   : std_logic;
   SIGNAL iown_out  : std_logic;
   SIGNAL memrn     : std_logic;
   SIGNAL memwn     : std_logic;
   SIGNAL wrdbus    : std_logic;

   -- Implicit buffer signal declarations
   SIGNAL AEN_internal : std_logic;


signal aenredge_s : std_logic;

   -- Component Declarations
   COMPONENT blk37
   PORT (
      abusl_in  : IN     std_logic_vector (3 DOWNTO 0);
      clk       : IN     std_logic ;
      csn       : IN     std_logic ;
      dbus_in   : IN     std_logic_vector (7 DOWNTO 0);
      dreq      : IN     std_logic_vector (3 DOWNTO 0);
      eop_in    : IN     std_logic ;
      hlda      : IN     std_logic ;
      iorn_in   : IN     std_logic ;
      iown_in   : IN     std_logic ;
      ready     : IN     std_logic ;
      reset     : IN     std_logic ;
      abush_out : OUT    std_logic_vector (3 DOWNTO 0);
      abusl_out : OUT    std_logic_vector (3 DOWNTO 0);
      adstb     : OUT    std_logic ;
      aen       : OUT    std_logic ;
      dack      : OUT    std_logic_vector (3 DOWNTO 0);
      dbus_out  : OUT    std_logic_vector (7 DOWNTO 0);
      eop_out   : OUT    std_logic ;
      hrq       : OUT    std_logic ;
      iorn_out  : OUT    std_logic ;
      iown_out  : OUT    std_logic ;
      memrn     : OUT    std_logic ;
      memwn     : OUT    std_logic ;
      wrdbus    : OUT    std_logic 
   );
   END COMPONENT;

BEGIN

   -------------------------------------------------------------------------------
   -- Tri-State Signal
   -------------------------------------------------------------------------------                                  
   NC   <= 'Z';                                                 -- Pin5 on the original 8237
   
   MEMR <= memrn when AEN_internal='1' else 'Z';
   MEMW <= memwn when AEN_internal='1' else 'Z';
   
   process (AEN_internal,iorn_out)
       begin  
           case AEN_internal is
               when '1'    => IOR <= iorn_out;                  -- Drive when bus is granted     
               when '0'    => IOR <= 'Z';
               when others => IOR <= 'X';         
           end case;    
   end process;   
   iorn_in <= IOR;   
   
   process (AEN_internal,iown_out)
       begin  
           case AEN_internal is
               when '1'    => IOW <= iown_out;                  -- Drive when bus is granted     
               when '0'    => IOW <= 'Z';
               when others => IOW <= 'X';         
           end case;    
   end process;   
   iown_in <= IOW;   
   
   
   process (AEN_internal,abusl_out)
       begin  
           case AEN_internal is
               when '1'    => ABUSL <= abusl_out;               -- Drive when bus is granted     
               when '0'    => ABUSL <= (others => 'Z');
               when others => ABUSL <= (others => 'X');         
           end case;    
   end process;   
   abusl_in <= ABUSL;   
   
   ABUSH <= abush_out when AEN_internal='1' else "ZZZZ";

   process (wrdbus,dbus_out)
       begin  
           case wrdbus is
               when '1'    => DB<= dbus_out;                    -- drive data bus
               when '0'    => DB<= (others => 'Z') after 5 ns;  
               when others => DB<= (others => 'X') after 5 ns;         
           end case;    
   end process;   
   dbus_in <= DB;                                               -- drive internal dbus    
                         

   -- HDL Embedded Text Block 3 eb2
   -- Use OBUFT             
   process (eop_out)
      begin  
       case eop_out is
           when '0'    => EOP<= '0';    
           when others => EOP<= 'Z';         
       end case;    
   end process;   
   
   process (RESET,CLK)
    begin
        if (RESET='1') then
            eop_in<='1';
        elsif falling_edge(CLK) then
            eop_in <= EOP;
        end if;
   end process;     

   -------------------------------------------------------------------------------
   -- Enable external busdrivers
   -- Use Rising Edge to delay AEN_internal negation by .5 clock cycles. This should be
   -- enough to keep the address stable after a rising edge of memw/iow
   -------------------------------------------------------------------------------
   process (clk,reset)
       begin
           if reset='1' then
            aenredge_s <= '0';      
           elsif rising_edge(clk) then
            aenredge_s <= aen_s;           
           end if;
   end process;                                 
   AEN_internal <= aen_s OR aenredge_s;             -- Create extra hold time

   -- Instance port mappings.
   TOP37 : blk37
      PORT MAP (
         abusl_in  => abusl_in,
         clk       => CLK,
         csn       => CS,
         dbus_in   => dbus_in,
         dreq      => DREQ,
         eop_in    => eop_in,
         hlda      => HLDA,
         iorn_in   => iorn_in,
         iown_in   => iown_in,
         ready     => READY,
         reset     => RESET,
         abush_out => abush_out,
         abusl_out => abusl_out,
         adstb     => ADSTB,
         aen       => aen_s,
         dack      => DACK,
         dbus_out  => dbus_out,
         eop_out   => eop_out,
         hrq       => HRQ,
         iorn_out  => iorn_out,
         iown_out  => iown_out,
         memrn     => memrn,
         memwn     => memwn,
         wrdbus    => wrdbus
      );

   -- Implicit buffered output assignments
   AEN <= AEN_internal;

END struct;
