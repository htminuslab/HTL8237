-------------------------------------------------------------------------------
--  HTL8237                                                                  --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : I8237                                                     --
-- Module        :                                                --
-- Library       :                                                           --
--                                                                           --
-- Version       : 1.0  20/01/2005   Created HT-LAB                          --
--               : 1.2  08/03/2016   Changed first/last logic                --
--               : 1.3  30/11/2023   Uploaded to github under MIT license    -- 
--                                   checked with Questa/Modelsim 2023.4     --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.NUMERIC_STD.all;

USE work.pack8237.all;

ENTITY blk37 IS
   PORT( 
      abusl_in  : IN     std_logic_vector (3 DOWNTO 0);
      clk       : IN     std_logic;
      csn       : IN     std_logic;
      dbus_in   : IN     std_logic_vector (7 DOWNTO 0);
      dreq      : IN     std_logic_vector (3 DOWNTO 0);
      eop_in    : IN     std_logic;
      hlda      : IN     std_logic;
      iorn_in   : IN     std_logic;
      iown_in   : IN     std_logic;
      ready     : IN     std_logic;
      reset     : IN     std_logic;
      abush_out : OUT    std_logic_vector (3 DOWNTO 0);
      abusl_out : OUT    std_logic_vector (3 DOWNTO 0);
      adstb     : OUT    std_logic;
      aen       : OUT    std_logic;
      dack      : OUT    std_logic_vector (3 DOWNTO 0);
      dbus_out  : OUT    std_logic_vector (7 DOWNTO 0);
      eop_out   : OUT    std_logic;
      hrq       : OUT    std_logic;
      iorn_out  : OUT    std_logic;
      iown_out  : OUT    std_logic;
      memrn     : OUT    std_logic;
      memwn     : OUT    std_logic;
      wrdbus    : OUT    std_logic
   );
END blk37 ;

ARCHITECTURE struct OF blk37 IS

   -- Architecture declarations
   signal mode_cnt : unsigned(1 downto 0);
   signal rddelay : std_logic_vector(1 downto 0);
   signal wrdelay : std_logic_vector(1 downto 0);
   signal abusmsb_s: std_logic_vector(7 downto 0);
   signal adstbredge_s : std_logic;
   signal abusl_in3 : std_logic;
   signal abusl_in3D : std_logic; -- Version 1.2, used for Z80

   -- Internal signal declarations
   SIGNAL adstb_s           : std_logic;
   SIGNAL aen_s             : std_logic;
   SIGNAL autoinit          : std_logic_vector(3 DOWNTO 0);
   SIGNAL autoinit0         : std_logic;
   SIGNAL autoinit1         : std_logic;
   SIGNAL autoinit2         : std_logic;
   SIGNAL autoinit3         : std_logic;
   SIGNAL borrowcarry0      : std_logic;
   SIGNAL borrowcarry1      : std_logic;
   SIGNAL borrowcarry2      : std_logic;
   SIGNAL borrowcarry3      : std_logic;
   SIGNAL ch0_address_hold  : std_logic;
   SIGNAL ch0_address_hold1 : std_logic;
   SIGNAL ch0_address_hold2 : std_logic;
   SIGNAL ch0_address_hold3 : std_logic;
   SIGNAL clr_firstlastff   : std_logic;
   SIGNAL clr_mode_cnt      : std_logic;
   SIGNAL command_reg       : std_logic_vector(7 DOWNTO 0);
   SIGNAL comp_timing       : std_logic;
   SIGNAL controller_dis    : std_logic;
   SIGNAL count_is_zero     : std_logic;
   SIGNAL count_is_zero0    : std_logic;
   SIGNAL count_is_zero1    : std_logic;
   SIGNAL count_is_zero2    : std_logic;
   SIGNAL count_is_zero3    : std_logic;
   SIGNAL current_addr0     : std_logic_vector(15 DOWNTO 0);
   SIGNAL current_addr1     : std_logic_vector(15 DOWNTO 0);
   SIGNAL current_addr2     : std_logic_vector(15 DOWNTO 0);
   SIGNAL current_addr3     : std_logic_vector(15 DOWNTO 0);
   SIGNAL current_cnt0      : std_logic_vector(15 DOWNTO 0);
   SIGNAL current_cnt1      : std_logic_vector(15 DOWNTO 0);
   SIGNAL current_cnt2      : std_logic_vector(15 DOWNTO 0);
   SIGNAL current_cnt3      : std_logic_vector(15 DOWNTO 0);
   SIGNAL dack_active_high  : std_logic;
   SIGNAL dma_bc            : std_logic;
   SIGNAL dma_chan          : std_logic_vector(1 DOWNTO 0);
   SIGNAL dma_mode          : std_logic_vector(1 DOWNTO 0);
   SIGNAL dma_req           : std_logic;
   SIGNAL dma_req_mode0     : std_logic;
   SIGNAL dma_transfer      : std_logic_vector(1 DOWNTO 0);
   SIGNAL dout              : std_logic;
   SIGNAL dreq_sense_low    : std_logic;
   SIGNAL endbuscycle       : std_logic;
   SIGNAL endbuscycle_s     : std_logic_vector(3 DOWNTO 0);
   SIGNAL eop_in_s          : std_logic_vector(3 DOWNTO 0);
   SIGNAL eop_latched       : std_logic;
   SIGNAL eop_out_s         : std_logic;
   SIGNAL extended_write    : std_logic;
   SIGNAL firstlast_ff      : std_logic;
   SIGNAL hrqn_s            : std_logic;
   SIGNAL iorn_s            : std_logic;
   SIGNAL iown_s            : std_logic;
   SIGNAL mask_reg          : std_logic_vector(3 DOWNTO 0);
   SIGNAL master_clear      : std_logic;
   SIGNAL mem_2_mem         : std_logic;
   SIGNAL mem_2_mem1        : std_logic;
   SIGNAL mem_2_mem2        : std_logic;
   SIGNAL mem_chan          : std_logic;
   SIGNAL memrn_s           : std_logic;
   SIGNAL memwn_s           : std_logic;
   SIGNAL mode_reg          : std_logic_vector(7 DOWNTO 0);
   SIGNAL mode_reg0         : std_logic_vector(5 DOWNTO 0);
   SIGNAL mode_reg1         : std_logic_vector(5 DOWNTO 0);
   SIGNAL mode_reg2         : std_logic_vector(5 DOWNTO 0);
   SIGNAL mode_reg3         : std_logic_vector(5 DOWNTO 0);
   SIGNAL rd                : std_logic;
   SIGNAL rdpulse           : std_logic;
   SIGNAL request_reg       : std_logic_vector(3 DOWNTO 0);
   SIGNAL rotate_priority   : std_logic;
   SIGNAL set_firstlastff   : std_logic;
   SIGNAL status_reg        : std_logic_vector(7 DOWNTO 0);
   SIGNAL tc                : std_logic_vector(3 DOWNTO 0);
   SIGNAL tc0               : std_logic;
   SIGNAL tc1               : std_logic;
   SIGNAL tc2               : std_logic;
   SIGNAL tc3               : std_logic;
   SIGNAL temp_reg          : std_logic_vector(7 DOWNTO 0);
   SIGNAL wr                : std_logic;
   SIGNAL wrpulse           : std_logic;


   -- Component Declarations
   COMPONENT channel
   GENERIC (
      channel_id : std_logic_vector(1 downto 0) := "00"
   );
   PORT (
      abusl_in         : IN     std_logic_vector (3 DOWNTO 0);
      dbus_in          : IN     std_logic_vector (7 DOWNTO 0);
      endbuscycle      : IN     std_logic ;
      eop_in           : IN     std_logic ;                    -- Active high!
      master_clear     : IN     std_logic ;
      firstlast_ff     : IN     std_logic ;
      wr               : IN     std_logic ;
      ch0_address_hold : IN     std_logic ;
      current_addr     : OUT    std_logic_vector (15 DOWNTO 0);
      current_count    : OUT    std_logic_vector (15 DOWNTO 0);
      mode_reg         : OUT    std_logic_vector (5 DOWNTO 0); -- only 7 DOWNTO 2, 1-0="11"
      tc               : OUT    std_logic ;
      mem_2_mem        : IN     std_logic ;
      clk              : IN     std_logic ;
      reset            : IN     std_logic ;
      borrowcarry      : OUT    std_logic ;
      autoinit         : OUT    std_logic ;
      count_is_zero    : OUT    std_logic 
   );
   END COMPONENT;
   COMPONENT dreqack
   PORT (
      abusl_in         : IN     std_logic_vector (3 DOWNTO 0);
      aen_s            : IN     std_logic ;
      autoinit         : IN     std_logic_vector (3 DOWNTO 0);
      clk              : IN     std_logic ;
      dack_active_high : IN     std_logic ;
      dbus_in          : IN     std_logic_vector (7 DOWNTO 0);
      dreq             : IN     std_logic_vector (3 DOWNTO 0);
      dreq_sense_low   : IN     std_logic ;
      endbuscycle      : IN     std_logic ;
      endbuscycle_s    : IN     std_logic_vector (3 DOWNTO 0);
      eop_in_s         : IN     std_logic_vector (3 DOWNTO 0);
      hlda             : IN     std_logic ;
      hrqn_s           : IN     std_logic ;
      master_clear     : IN     std_logic ;
      mem_2_mem        : IN     std_logic ;
      mem_chan         : IN     std_logic ;
      rd               : IN     std_logic ;
      reset            : IN     std_logic ;
      rotate_priority  : IN     std_logic ;
      tc               : IN     std_logic_vector (3 DOWNTO 0);
      wr               : IN     std_logic ;
      dack             : OUT    std_logic_vector (3 DOWNTO 0);
      dma_chan         : OUT    std_logic_vector (1 DOWNTO 0);
      dma_req          : OUT    std_logic ;
      dma_req_mode0    : OUT    std_logic ;
      mask_reg         : OUT    std_logic_vector (3 DOWNTO 0);
      request_reg      : OUT    std_logic_vector (3 DOWNTO 0);
      status_reg       : OUT    std_logic_vector (7 DOWNTO 0);
      eop_latched      : IN     std_logic;
      rdpulse          : IN     std_logic     -- Version 1.3
   );
   END COMPONENT;
   COMPONENT fsm37
   PORT (
      clk            : IN     std_logic ;
      comp_timing    : IN     std_logic ;
      controller_dis : IN     std_logic ;
      count_is_zero  : IN     std_logic ;
      dma_bc         : IN     std_logic ;
      dma_mode       : IN     std_logic_vector (1 DOWNTO 0);
      dma_req        : IN     std_logic ;
      dma_req_mode0  : IN     std_logic ;
      dma_transfer   : IN     std_logic_vector (1 DOWNTO 0);
      eop_in         : IN     std_logic ;
      extended_write : IN     std_logic ;
      hlda           : IN     std_logic ;
      mem_2_mem      : IN     std_logic ;
      ready          : IN     std_logic ;
      reset          : IN     std_logic ;
      adstb_s        : OUT    std_logic ;
      aen_s          : OUT    std_logic ;
      endbuscycle    : OUT    std_logic ;
      eop_latched    : OUT    std_logic ;
      eop_out_s      : OUT    std_logic ;
      hrqn_s         : OUT    std_logic ;
      iorn_s         : OUT    std_logic ;
      iown_s         : OUT    std_logic ;
      mem_chan       : OUT    std_logic ;
      memrn_s        : OUT    std_logic ;
      memwn_s        : OUT    std_logic 
   );
   END COMPONENT;

BEGIN
   -- Architecture concurrent statements
   wr<='1' when csn='0' AND iown_in='0' AND hlda='0' else '0';
   
   rd<='1' when csn='0' AND iorn_in='0' AND hlda='0' else '0';
   
   -------------------------------------------------------------------------------
   -- master clear   command
   -------------------------------------------------------------------------------
   master_clear <= '1' when wr='1' AND abusl_in=MASTER_CLEAR_C else '0';
   
   -------------------------------------------------------------------------------
   -- Clear First/Last Flip-Flop is executed prior to writing or reading 
   -- new address or word count information to the 82C37A. This command 
   -- initializes the flip-flop to a known state (low byte first) so that 
   -- subsequent accesses to register contents by the microprocessor will address
   -- upper and lower bytes in the correct sequence.
   -------------------------------------------------------------------------------
   clr_firstlastff <= '1' when   wr='1' AND abusl_in=CLEAR_FIRSTLASTFF_C else '0';
   
   -------------------------------------------------------------------------------
   -- Set First/Last Flip-Flop command will set the flip-flop to select the 
   -- high byte first on read and write operations to address and word count 
   -- registers.
   -------------------------------------------------------------------------------
   set_firstlastff <= '1' when rd='1' AND abusl_in=SET_FIRSTLASTFF_C else '0';
   
   -------------------------------------------------------------------------------
   -- Combine some channel signal into vectors
   -------------------------------------------------------------------------------
   autoinit <= autoinit3 & autoinit2 & autoinit1 & autoinit0; 
   
   -------------------------------------------------------------------------------
   -- Clear Mode Register Counter - Since only one address
   -- location is available for reading the Mode registers, an internal
   -- two-bit counter has been included to select Mode registers
   -- during read operation. To read the Mode registers, first
   -- execute the Clear Mode Register Counter command, then
   -- do consecutive reads until the desired channel is read. Read
   -- order is channel 0 first, channel 3 last. The lower two bits on
   -- all Mode registers will read as ones.
   -------------------------------------------------------------------------------
   clr_mode_cnt <= '1' when (rd='1' AND abusl_in=CLEAR_MODE_REG_CNT_C) else '0';
   
   
   -------------------------------------------------------------------------------
   -- Create single clk falling edge RD/WR pulse
   -------------------------------------------------------------------------------
   process (clk,reset)                                         
       begin
         if (reset='1') then    
            rddelay   <= "00";  
            wrdelay   <= "00";
            abusl_in3 <= '0';
            abusl_in3D <= '0';                          -- version 1.2, extra delay for Z80
         elsif (falling_edge(clk)) then
            rddelay   <= rddelay(0) & rd;
            wrdelay   <= wrdelay(0) & wr;
            abusl_in3 <= abusl_in(3);
            abusl_in3D<=abusl_in3;                      -- version 1.2, extra delay for Z80
         end if;  
   end process;
   
   -- process (clk,reset)                                          
       -- begin
         -- if (reset='1') then     
            -- rddelay   <= "00";   
            -- wrdelay   <= "00";
            -- abusl_in3 <= '0';                       -- Version 1.2
         -- elsif (falling_edge(clk)) then 
            -- rddelay   <= rddelay(0) & rd;
            -- wrdelay   <= wrdelay(0) & wr;
            -- abusl_in3 <= abusl_in(3);               -- Version 1.2
         -- end if;   
   -- end process;
   
   -- rdpulse <= rddelay(0) AND NOT(rddelay(1));   
   -- wrpulse <= wrdelay(0) AND NOT(wrdelay(1));   
   rdpulse <= rddelay(1) AND NOT(rddelay(0));       -- Version 1.2
   wrpulse <= wrdelay(1) AND NOT(wrdelay(0));       -- Version 1.2
   
   
   -------------------------------------------------------------------------------
   -- First/Last Toggle FF
   -- Only toggle when reading/writing to channel registers (a3=0)
   -------------------------------------------------------------------------------
   process(reset, clk) 
       begin
           if (reset='1') then
               firstlast_ff <= '0';   
           elsif falling_edge(clk) then
               if master_clear='1' OR clr_firstlastff='1' then
                   firstlast_ff <= '0';
               elsif set_firstlastff='1' then
                   firstlast_ff <= '1';
               --elsif ((wrpulse='1' OR rdpulse='1') AND abusl_in(3)='0') then
               elsif ((wrpulse='1' OR rdpulse='1') AND abusl_in3D='0') then -- Version 1.2
                   firstlast_ff <= NOT firstlast_ff;       
               end if;
         end if;
   end process;  
   
   -------------------------------------------------------------------------------
   -- Command Register
   -------------------------------------------------------------------------------
   process (reset,clk)
       begin
           if reset='1' then
               mem_2_mem       <= '0';
               ch0_address_hold<= '0';
               controller_dis  <= '0';
               comp_timing     <= '0';
               rotate_priority <= '0';
               extended_write  <= '0';
               dreq_sense_low  <= '0';
               dack_active_high<= '0';
           elsif falling_edge(clk) then
               if master_clear='1' then
                   mem_2_mem       <= '0';
                   ch0_address_hold<= '0';
                   controller_dis  <= '0';
                   comp_timing     <= '0';
                   rotate_priority <= '0';
                   extended_write  <= '0';
                   dreq_sense_low  <= '0';
                   dack_active_high<= '0';
               elsif wr='1' AND abusl_in=WRITE_COMMAND_REG_C then
                   mem_2_mem       <= dbus_in(0);
                   ch0_address_hold<= dbus_in(1);
                   controller_dis  <= dbus_in(2);
                   comp_timing     <= dbus_in(3) AND (NOT dbus_in(0));  -- Not allowed when mem_2_mem='1'
                   rotate_priority <= dbus_in(4);
                   extended_write  <= dbus_in(5);        
                   dreq_sense_low  <= dbus_in(6);
                   dack_active_high<= dbus_in(7);
                assert (dbus_in(0) AND dbus_in(3))='0' report "Compressed Timing is not allowed for memory_2_memory transfers" severity warning;
               end if;
           end if;
   end process;
   
   command_reg<= dack_active_high & dreq_sense_low & extended_write & rotate_priority &
                 comp_timing & controller_dis & ch0_address_hold & mem_2_mem;  
   
   -------------------------------------------------------------------------------
   -- Temporary 8-bits Register used for memory to memory transfers
   -------------------------------------------------------------------------------
   process (clk,reset)
       begin
        if reset='1' then
               temp_reg <= (others => '0');
           elsif falling_edge(clk) then
               if memrn_s='0' AND mem_2_mem='1' then 
                   temp_reg <= dbus_in;
               end if;
           end if;
   end process;
   
   -------------------------------------------------------------------------------
   -- Enable external busdrivers
   -- aen is not asserted when dma_mode=Cascade
   -------------------------------------------------------------------------------
   aen<='1' when aen_s='1' AND hlda='1' AND dma_mode/="11" else '0';

   -------------------------------------------------------------------------------   
   -- Select mode/transfer bits from active channel
   -------------------------------------------------------------------------------
   process (dma_chan,mode_reg0,mode_reg1,mode_reg2,mode_reg3) 
       begin   
           case dma_chan is
               when "00"   => dma_mode     <= mode_reg0(5 downto 4);
                              dma_transfer <= mode_reg0(1 downto 0);
               when "01"   => dma_mode     <= mode_reg1(5 downto 4);
                              dma_transfer <= mode_reg1(1 downto 0);
               when "10"   => dma_mode     <= mode_reg2(5 downto 4);
                              dma_transfer <= mode_reg2(1 downto 0);
               when others => dma_mode     <= mode_reg3(5 downto 4); 
                              dma_transfer <= mode_reg3(1 downto 0);             
           end case;   
   end process;                                      
   
   -------------------------------------------------------------------------------
   -- Select Carry/Borrow signal from active channel
   -------------------------------------------------------------------------------  
   process (dma_chan,borrowcarry0,borrowcarry1,borrowcarry2,borrowcarry3) 
       begin   
           case dma_chan is
               when "00"   => dma_bc <= borrowcarry0;
               when "01"   => dma_bc <= borrowcarry1;
               when "10"   => dma_bc <= borrowcarry2;
               when others => dma_bc <= borrowcarry3;              
           end case;   
   end process;                                      
   
   -------------------------------------------------------------------------------
   -- Mode counter
   -- Only one address location is available for reading the Mode registers, 
   -- an internal two-bit counter has been included to select Mode registers
   -- during read operation. To read the Mode registers, first execute the 
   -- Clear Mode Register Counter command, then do consecutive reads until 
   -- the desired channel is read. Read order is channel 0 first, channel 3 last. 
   -- The lower two bits on all Mode registers will read as ones.
   -------------------------------------------------------------------------------
   process (clk,reset)                                                    
       begin
           if (reset='1') then                     
               mode_cnt <= (others => '0');              
           elsif (falling_edge(clk)) then 
               if master_clear='1' or clr_mode_cnt='1' then 
                   mode_cnt <= (others => '0'); 
               elsif rdpulse='1' AND abusl_in=READ_MODE_REG_C then  -- After each rd increase counter
                   mode_cnt <= mode_cnt + 1;   
               end if;
           end if;   
   end process;    
   
   process (mode_cnt,mode_reg0,mode_reg1,mode_reg2,mode_reg3) 
      begin
         case mode_cnt is
            when "00"  => mode_reg <= mode_reg0&"11"; 
            when "01"  => mode_reg <= mode_reg1&"11";  
            when "10"  => mode_reg <= mode_reg2&"11";    
            when others=> mode_reg <= mode_reg3&"11";              
         end case;   
   end process;                                      

   -------------------------------------------------------------------------------
   -- Select terminal count from active channel mode register
   -- A pulse is generated by the 82C37A when terminal count (TC) for any channel 
   -- is reached,except for channel 0 in memory-to-memory mode. During mem-2-mem 
   -- transfers, EOP will be output when the TC for channel 1 occurs.
   -- 
   -- EOP will output in S2 if compressed timing is selected.
   -- EOP is disabled during Cascade mode
   -------------------------------------------------------------------------------
   process (mem_2_mem,dma_mode,dma_chan,count_is_zero0,count_is_zero1,count_is_zero2,count_is_zero3) 
       begin  
           if mem_2_mem='1' then                -- Memory to Memory Transfer
                count_is_zero <= count_is_zero1;
           elsif dma_mode="11" then             -- Cascade Mode
                count_is_zero <= '0';               -- don't care
           else
               case dma_chan is
                   when "00"   => count_is_zero <= count_is_zero0;
                   when "01"   => count_is_zero <= count_is_zero1;
                   when "10"   => count_is_zero <= count_is_zero2;
                   when others => count_is_zero <= count_is_zero3;            
               end case;  
           end if; 
   end process;                                      
   
   -- Combine some channel signal into a vector
   tc  <= tc3 & tc2 & tc1 & tc0;
   
   process (reset,clk) 
       begin    
        if (reset='1') then
            eop_out <= '1';   
        elsif falling_edge(clk) then
            eop_out <= NOT eop_out_s;           -- eop_out_s is controlled by fsm37 S4/S24
        end if;
   end process; 

   -------------------------------------------------------------------------------
   -- dbus Tri-state buffer control   
   -------------------------------------------------------------------------------
   wrdbus <= '1' when (hlda='1' AND ((memwn_s='0' AND mem_2_mem='1') OR adstbredge_s='1')) OR
                      (hlda='0' AND csn='0' AND iorn_in='0') else '0';
               
   -------------------------------------------------------------------------------
   -- Delay adstb by half a clock cycle, this to create an address hold
   -- during S4 to S1 transition
   -------------------------------------------------------------------------------
   process (clk,reset) 
       begin  
           if reset='1' then 
               adstbredge_s <= '0';
           elsif rising_edge(clk) then 
               adstbredge_s <= adstb_s;
           end if;
   end process;                                      
   adstb <= adstbredge_s;
   
   -------------------------------------------------------------------------------
   -- Databus Out Multiplexer
   -------------------------------------------------------------------------------
   process (hlda,rd,mem_2_mem,memwn_s,adstbredge_s,abusl_in,current_addr0,current_cnt0,current_addr1,current_cnt1,
            current_addr2,current_cnt2,current_addr3,current_cnt3,status_reg, request_reg, command_reg,
            mode_reg,temp_reg, mask_reg,firstlast_ff,abusmsb_s) 
       begin   
           if (hlda='1' AND mem_2_mem='1' AND memwn_s='0') then
               dbus_out <= temp_reg;                -- Memory to Memory Transfer                   
           elsif adstbredge_s='1' then                  -- Create half a clockcycle delay
             dbus_out <= abusmsb_s;                 -- Output MSB address
           elsif (rd='1') then
               case abusl_in is
                   when "0000"  => if firstlast_ff='0' then dbus_out <= current_addr0(7 downto 0);
                                                       else dbus_out <= current_addr0(15 downto 8);
                                   end if;
                   when "0001"  => if firstlast_ff='0' then dbus_out <= current_cnt0(7 downto 0);
                                                       else dbus_out <= current_cnt0(15 downto 8);
                                   end if;
                   when "0010"  => if firstlast_ff='0' then dbus_out <= current_addr1(7 downto 0);
                                                       else dbus_out <= current_addr1(15 downto 8);
                                   end if;
                   when "0011"  => if firstlast_ff='0' then dbus_out <= current_cnt1(7 downto 0);
                                                       else dbus_out <= current_cnt1(15 downto 8);
                                   end if;
                   when "0100"  => if firstlast_ff='0' then dbus_out <= current_addr2(7 downto 0);
                                                       else dbus_out <= current_addr2(15 downto 8);
                                   end if;
                   when "0101"  => if firstlast_ff='0' then dbus_out <= current_cnt2(7 downto 0);
                                                       else dbus_out <= current_cnt2(15 downto 8);
                                   end if;
                   when "0110"  => if firstlast_ff='0' then dbus_out <= current_addr3(7 downto 0);
                                                       else dbus_out <= current_addr3(15 downto 8);
                                   end if;
                   when "0111"  => if firstlast_ff='0' then dbus_out <= current_cnt3(7 downto 0);
                                                       else dbus_out <= current_cnt3(15 downto 8);
                                   end if;
   
                   when "1000"  => dbus_out <= status_reg;
                   when "1001"  => dbus_out <= "1111"&request_reg;    
                   when "1010"  => dbus_out <= command_reg;
                   when "1011"  => dbus_out <= mode_reg;
               --  when "1100"  => used for set first/last FF
                   when "1101"  => dbus_out <= temp_reg;
               --  when "1110"  => used for set clear mode reg. counter
                   when "1111"  => dbus_out <= "1111"&mask_reg;   -- 7..4 always read as 1   
                   when others  => dbus_out <= "--------";              
               end case;  
        else
            dbus_out <= "--------";                 -- avoid latches
           end if;
   end process;                                      
   
   
   
   -------------------------------------------------------------------------------
   -- abusmsb multiplexer, used to drive Databus during adstb strobe
   -------------------------------------------------------------------------------
   process (dma_chan,current_addr0,current_addr1,current_addr2,current_addr3) 
       begin   
           case dma_chan is
               when "00"   => abusmsb_s <= current_addr0(15 downto 8);
               when "01"   => abusmsb_s <= current_addr1(15 downto 8);
               when "10"   => abusmsb_s <= current_addr2(15 downto 8);
               when others => abusmsb_s <= current_addr3(15 downto 8);             
           end case;   
   end process;                                      
   
   -------------------------------------------------------------------------------
   -- abus multiplexer
   -- Clocked on rising_edge! to create half a clockcycle of address hold.
   -------------------------------------------------------------------------------
   process (clk) 
       begin  
        if rising_edge(clk) then 
            case dma_chan is
                when "00"  => abusl_out <= current_addr0(3 downto 0); 
                                 abush_out <= current_addr0(7 downto 4);
                   when "01"  => abusl_out <= current_addr1(3 downto 0); 
                                 abush_out <= current_addr1(7 downto 4);
                   when "10"  => abusl_out <= current_addr2(3 downto 0); 
                                 abush_out <= current_addr2(7 downto 4);
                   when others=> abusl_out <= current_addr3(3 downto 0); 
                                 abush_out <= current_addr3(7 downto 4);
               end case;   
        end if;
   end process;                                      

   memwn    <= memwn_s;
   memrn    <= memrn_s;
   iown_out <= iown_s;
   iorn_out <= iorn_s;
   hrq      <= NOT hrqn_s;

   -------------------------------------------------------------------------------      
   -- Select which channel received the endbuscycle signal. For memory_2_memory
   -- assert both CH0 and CH1 signals
   -------------------------------------------------------------------------------
   process (dma_chan,endbuscycle,mem_2_mem) 
       begin
           if mem_2_mem='1' then
               endbuscycle_s <= "00" & endbuscycle & endbuscycle;
           else 
               case dma_chan is
                   when "00"   => endbuscycle_s <= "000" & endbuscycle; 
                   when "01"   => endbuscycle_s <= "00" & endbuscycle & '0';
                   when "10"   => endbuscycle_s <= '0' & endbuscycle &"00";
                   when others => endbuscycle_s <= endbuscycle &"000";           
               end case;  
           end if; 
   end process;                                      

   -------------------------------------------------------------------------------       
   -- Select which channel received the external EOP input signal. For memory_2_memory
   -- assert only CH1 eop_in signals
   -------------------------------------------------------------------------------  
   process (endbuscycle,dma_chan,eop_latched,mem_2_mem) 
       begin
        if endbuscycle='1' then
            if mem_2_mem='1' then
                eop_in_s <= "00" & eop_latched & '0';
            else 
                case dma_chan is
                    when "00"   => eop_in_s <= "000" & eop_latched;
                    when "01"   => eop_in_s <= "00" & eop_latched & '0';
                    when "10"   => eop_in_s <= '0'& eop_latched & "00";
                    when others => eop_in_s <= eop_latched & "000";           
                end case;  
            end if; 
        else
            eop_in_s <= (others => '0');
        end if;
   end process;                                      


   ch0_address_hold1 <= '0';
   ch0_address_hold2 <= '0';
   ch0_address_hold3 <= '0';
   mem_2_mem1 <= '0';
   mem_2_mem2 <= '0';
   dout <= '0';

   -- Instance port mappings.
   ICH0 : channel
      GENERIC MAP (
         channel_id => "00"
      )
      PORT MAP (
         abusl_in         => abusl_in,
         dbus_in          => dbus_in,
         endbuscycle      => endbuscycle_s(0),
         eop_in           => eop_in_s(0),
         master_clear     => master_clear,
         firstlast_ff     => firstlast_ff,
         wr               => wr,
         ch0_address_hold => ch0_address_hold,
         current_addr     => current_addr0,
         current_count    => current_cnt0,
         mode_reg         => mode_reg0,
         tc               => tc0,
         mem_2_mem        => mem_2_mem,
         clk              => clk,
         reset            => reset,
         borrowcarry      => borrowcarry0,
         autoinit         => autoinit0,
         count_is_zero    => count_is_zero0
      );
   ICH1 : channel
      GENERIC MAP (
         channel_id => "01"
      )
      PORT MAP (
         abusl_in         => abusl_in,
         dbus_in          => dbus_in,
         endbuscycle      => endbuscycle_s(1),
         eop_in           => eop_in_s(1),
         master_clear     => master_clear,
         firstlast_ff     => firstlast_ff,
         wr               => wr,
         ch0_address_hold => ch0_address_hold1,
         current_addr     => current_addr1,
         current_count    => current_cnt1,
         mode_reg         => mode_reg1,
         tc               => tc1,
         mem_2_mem        => mem_2_mem1,
         clk              => clk,
         reset            => reset,
         borrowcarry      => borrowcarry1,
         autoinit         => autoinit1,
         count_is_zero    => count_is_zero1
      );
   ICH2 : channel
      GENERIC MAP (
         channel_id => "10"
      )
      PORT MAP (
         abusl_in         => abusl_in,
         dbus_in          => dbus_in,
         endbuscycle      => endbuscycle_s(2),
         eop_in           => eop_in_s(2),
         master_clear     => master_clear,
         firstlast_ff     => firstlast_ff,
         wr               => wr,
         ch0_address_hold => ch0_address_hold2,
         current_addr     => current_addr2,
         current_count    => current_cnt2,
         mode_reg         => mode_reg2,
         tc               => tc2,
         mem_2_mem        => mem_2_mem2,
         clk              => clk,
         reset            => reset,
         borrowcarry      => borrowcarry2,
         autoinit         => autoinit2,
         count_is_zero    => count_is_zero2
      );
   ICH3 : channel
      GENERIC MAP (
         channel_id => "11"
      )
      PORT MAP (
         abusl_in         => abusl_in,
         dbus_in          => dbus_in,
         endbuscycle      => endbuscycle_s(3),
         eop_in           => eop_in_s(3),
         master_clear     => master_clear,
         firstlast_ff     => firstlast_ff,
         wr               => wr,
         ch0_address_hold => ch0_address_hold3,
         current_addr     => current_addr3,
         current_count    => current_cnt3,
         mode_reg         => mode_reg3,
         tc               => tc3,
         mem_2_mem        => dout,
         clk              => clk,
         reset            => reset,
         borrowcarry      => borrowcarry3,
         autoinit         => autoinit3,
         count_is_zero    => count_is_zero3
      );
   DRQA : dreqack
      PORT MAP (
         abusl_in         => abusl_in,
         aen_s            => aen_s,
         autoinit         => autoinit,
         clk              => clk,
         dack_active_high => dack_active_high,
         dbus_in          => dbus_in,
         dreq             => dreq,
         dreq_sense_low   => dreq_sense_low,
         endbuscycle      => endbuscycle,
         endbuscycle_s    => endbuscycle_s,
         eop_in_s         => eop_in_s,
         hlda             => hlda,
         hrqn_s           => hrqn_s,
         master_clear     => master_clear,
         mem_2_mem        => mem_2_mem,
         mem_chan         => mem_chan,
         rd               => rd,
         reset            => reset,
         rotate_priority  => rotate_priority,
         tc               => tc,
         wr               => wr,
         dack             => dack,
         dma_chan         => dma_chan,
         dma_req          => dma_req,
         dma_req_mode0    => dma_req_mode0,
         mask_reg         => mask_reg,
         request_reg      => request_reg,
         status_reg       => status_reg,
         eop_latched      => eop_latched,
         rdpulse          => rdpulse   -- Version 1.3
      );
   FSM : fsm37
      PORT MAP (
         clk            => clk,
         comp_timing    => comp_timing,
         controller_dis => controller_dis,
         count_is_zero  => count_is_zero,
         dma_bc         => dma_bc,
         dma_mode       => dma_mode,
         dma_req        => dma_req,
         dma_req_mode0  => dma_req_mode0,
         dma_transfer   => dma_transfer,
         eop_in         => eop_in,
         extended_write => extended_write,
         hlda           => hlda,
         mem_2_mem      => mem_2_mem,
         ready          => ready,
         reset          => reset,
         adstb_s        => adstb_s,
         aen_s          => aen_s,
         endbuscycle    => endbuscycle,
         eop_latched    => eop_latched,
         eop_out_s      => eop_out_s,
         hrqn_s         => hrqn_s,
         iorn_s         => iorn_s,
         iown_s         => iown_s,
         mem_chan       => mem_chan,
         memrn_s        => memrn_s,
         memwn_s        => memwn_s
      );

END struct;
