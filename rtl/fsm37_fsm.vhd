-------------------------------------------------------------------------------
--  HTL8237                                                                  --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : I8237                                                     --
-- Module        : Control FSM                                               --
-- Library       :                                                           --
--                                                                           --
-- Version       : 1.0  20/01/2005   Created HT-LAB                          --
--               : 1.1  20/11/2023   Uploaded to github under MIT license    -- 
--                                   checked with Questa/Modelsim 2023.4     --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.NUMERIC_STD.all;

USE work.pack8237.all;

ENTITY fsm37 IS
   PORT( 
      clk            : IN     std_logic;
      comp_timing    : IN     std_logic;
      controller_dis : IN     std_logic;
      count_is_zero  : IN     std_logic;
      dma_bc         : IN     std_logic;
      dma_mode       : IN     std_logic_vector (1 DOWNTO 0);
      dma_req        : IN     std_logic;
      dma_req_mode0  : IN     std_logic;
      dma_transfer   : IN     std_logic_vector (1 DOWNTO 0);
      eop_in         : IN     std_logic;
      extended_write : IN     std_logic;
      hlda           : IN     std_logic;
      mem_2_mem      : IN     std_logic;
      ready          : IN     std_logic;
      reset          : IN     std_logic;
      adstb_s        : OUT    std_logic;
      aen_s          : OUT    std_logic;
      endbuscycle    : OUT    std_logic;
      eop_latched    : OUT    std_logic;
      eop_out_s      : OUT    std_logic;
      hrqn_s         : OUT    std_logic;
      iorn_s         : OUT    std_logic;
      iown_s         : OUT    std_logic;
      mem_chan       : OUT    std_logic;
      memrn_s        : OUT    std_logic;
      memwn_s        : OUT    std_logic
   );
END fsm37 ;
 
ARCHITECTURE fsm OF fsm37 IS

   -- Architecture Declarations
   signal firstcycle : std_logic;

   TYPE STATE_TYPE IS (
      Sidle,
      S0,
      S1,
      S2,
      S3,
      S4,
      SW,
      SWm1,
      S21,
      SWm2,
      S11,
      S12,
      S13,
      S14,
      S24,
      S22,
      S23,
      Scas
   );
 
   -- Declare current and next state signals
   SIGNAL current_state : STATE_TYPE;
   SIGNAL next_state : STATE_TYPE;

   -- Declare any pre-registered internal signals
   SIGNAL eop_latched_cld : std_logic ;
   SIGNAL hrqn_s_cld : std_logic ;
   SIGNAL iorn_s_cld : std_logic ;
   SIGNAL iown_s_cld : std_logic ;
   SIGNAL mem_chan_cld : std_logic ;
   SIGNAL memrn_s_cld : std_logic ;
   SIGNAL memwn_s_cld : std_logic ;

BEGIN

   -----------------------------------------------------------------
   clocked_proc : PROCESS ( 
      clk,
      reset
   )
   -----------------------------------------------------------------
   BEGIN
      IF (reset = '1') THEN
         current_state <= Sidle;
         -- Default Reset Values
         eop_latched_cld <= '0';
         hrqn_s_cld <= '1';
         iorn_s_cld <= '1';
         iown_s_cld <= '1';
         mem_chan_cld <= '0';
         memrn_s_cld <= '1';
         memwn_s_cld <= '1';
         firstcycle <= '1';
      ELSIF (clk'EVENT AND clk = '0') THEN
         current_state <= next_state;

         -- Combined Actions
         CASE current_state IS
            WHEN Sidle => 
               hrqn_s_cld <='1';
               eop_latched_cld<= '0';
            WHEN S0 => 
               if controller_dis='0' then
                   hrqn_s_cld <='0';
               end if;
               firstcycle<='1';
            WHEN S1 => 
               eop_latched_cld<= NOT eop_in;
            WHEN S2 => 
               if dma_transfer="01" then
                  if extended_write='1' OR comp_timing='1' then  
                       memwn_s_cld<='0'; 
                  end if;
                  iorn_s_cld<='0';
               elsif dma_transfer="10" then  
                 if extended_write='1' OR comp_timing='1' then 
                       iown_s_cld<='0';
                 end if;
                 memrn_s_cld<='0';
               end if;
               IF (comp_timing='1') THEN 
                  if (eop_latched_cld='0') then
                     eop_latched_cld<= NOT eop_in;
                  end if;
               ELSE
                  if (eop_latched_cld='0') then
                     eop_latched_cld<= NOT eop_in;
                  end if;
               END IF;
            WHEN S3 => 
               if dma_transfer="01" then
                  memwn_s_cld<='0'; 
               elsif dma_transfer="10" then  
                 iown_s_cld<='0';
               end if;
            WHEN S4 => 
               IF (count_is_zero='1' OR hlda='0' OR dma_mode="01" 
                   OR (dma_mode="00" AND dma_req_mode0='0') 
                   OR eop_latched_cld='1' OR eop_in='0') THEN 
                  hrqn_s_cld<='1';
                  firstcycle<='0';
                  memrn_s_cld<='1';
                  memwn_s_cld<='1';
                  iorn_s_cld<='1';
                  iown_s_cld<='1';
               ELSIF (dma_bc='1') THEN 
                  firstcycle<='0';
                  memrn_s_cld<='1';
                  memwn_s_cld<='1';
                  iorn_s_cld<='1';
                  iown_s_cld<='1';
               ELSE
                  firstcycle<='0';
                  memrn_s_cld<='1';
                  memwn_s_cld<='1';
                  iorn_s_cld<='1';
                  iown_s_cld<='1';
               END IF;
            WHEN S21 => 
               mem_chan_cld<='1';
               IF (dma_bc='1' OR firstcycle='1') THEN 
                  if (eop_latched_cld='0') then
                     eop_latched_cld<= NOT eop_in;
                  end if;
               END IF;
            WHEN S11 => 
               mem_chan_cld<='0';
               eop_latched_cld<= NOT eop_in;
            WHEN S12 => 
               if dma_transfer/="00" then
                   memrn_s_cld <= '0';
               end if;
               if (eop_latched_cld='0') then
                  eop_latched_cld<= NOT eop_in;
               end if;
            WHEN S14 => 
               memrn_s_cld<='1';
            WHEN S24 => 
               memwn_s_cld <='1';
               IF (count_is_zero='1' OR hlda='0'
                   OR eop_latched_cld='1'
                   OR eop_in='0') THEN 
                  hrqn_s_cld<='1';
               END IF;
            WHEN S22 => 
               if extended_write='1' AND 
                   dma_transfer/="00" then
                     memwn_s_cld<='0';
               end if;
               if (eop_latched_cld='0') then
                  eop_latched_cld<= NOT eop_in;
               end if;
            WHEN S23 => 
               if dma_transfer/="00" then
                   memwn_s_cld <='0';
               end if;
            WHEN Scas => 
               IF (hlda='0' OR 
                   dma_req_mode0='0') THEN 
                  hrqn_s_cld<='1';
               END IF;
            WHEN OTHERS =>
               NULL;
         END CASE;
      END IF;
   END PROCESS clocked_proc;
 
   -----------------------------------------------------------------
   nextstate_proc : PROCESS ( 
      comp_timing,
      count_is_zero,
      current_state,
      dma_bc,
      dma_mode,
      dma_req,
      dma_req_mode0,
      dma_transfer,
      eop_in,
      eop_latched_cld,
      firstcycle,
      hlda,
      mem_2_mem,
      ready
   )
   -----------------------------------------------------------------
   BEGIN
      -- Default Assignment
      adstb_s <= '0';
      aen_s <= '1';
      endbuscycle <= '0';
      eop_out_s <= '0';

      -- Combined Actions
      CASE current_state IS
         WHEN Sidle => 
            aen_s<='0';
            IF (dma_req='1') THEN 
               next_state <= S0;
            ELSE
               next_state <= Sidle;
            END IF;
         WHEN S0 => 
            aen_s<='0';
            IF (dma_req='0') THEN 
               next_state <= Sidle;
            ELSIF (hlda='1' AND
                   dma_mode="11") THEN 
               next_state <= Scas;
            ELSIF (hlda='1' AND 
                   mem_2_mem='1') THEN 
               next_state <= S11;
            ELSIF (hlda='1' AND 
                   mem_2_mem='0') THEN 
               next_state <= S1;
            ELSE
               next_state <= S0;
            END IF;
         WHEN S1 => 
            adstb_s<='1';
            next_state <= S2;
         WHEN S2 => 
            IF (comp_timing='1') THEN 
               if count_is_zero='1' then
                   eop_out_s<='1';
               end if;
               next_state <= S4;
            ELSE
               next_state <= S3;
            END IF;
         WHEN S3 => 
            IF (ready='1') THEN 
               if count_is_zero='1' then
                   eop_out_s<='1';
               end if;
               next_state <= S4;
            ELSIF (ready='0') THEN 
               next_state <= SW;
            ELSE
               next_state <= S3;
            END IF;
         WHEN S4 => 
            IF (count_is_zero='1' OR hlda='0' OR dma_mode="01" 
                OR (dma_mode="00" AND dma_req_mode0='0') 
                OR eop_latched_cld='1' OR eop_in='0') THEN 
               endbuscycle<='1';
               next_state <= Sidle;
            ELSIF (dma_bc='1') THEN 
               endbuscycle<='1';
               next_state <= S1;
            ELSE
               endbuscycle<='1';
               next_state <= S2;
            END IF;
         WHEN SW => 
            IF (ready='1') THEN 
               if count_is_zero='1' then
                   eop_out_s<='1';
               end if;
               next_state <= S4;
            ELSE
               next_state <= SW;
            END IF;
         WHEN SWm1 => 
            next_state <= S13;
         WHEN S21 => 
            adstb_s<='1';
            IF (dma_bc='1' OR firstcycle='1') THEN 
               next_state <= S22;
            ELSE
               next_state <= S21;
            END IF;
         WHEN SWm2 => 
            next_state <= S23;
         WHEN S11 => 
            adstb_s<='1';
            next_state <= S12;
         WHEN S12 => 
            next_state <= S13;
         WHEN S13 => 
            IF (ready='1' OR dma_transfer="00") THEN 
               next_state <= S14;
            ELSIF (ready='0') THEN 
               next_state <= SWm1;
            ELSE
               next_state <= S13;
            END IF;
         WHEN S14 => 
            next_state <= S21;
         WHEN S24 => 
            IF (count_is_zero='1' OR hlda='0'
                OR eop_latched_cld='1'
                OR eop_in='0') THEN 
               endbuscycle<='1';
               next_state <= Sidle;
            ELSE
               endbuscycle<='1';
               next_state <= S11;
            END IF;
         WHEN S22 => 
            next_state <= S23;
         WHEN S23 => 
            IF (ready='1' OR dma_transfer="00") THEN 
               if count_is_zero='1' then
                   eop_out_s<='1';
               end if;
               next_state <= S24;
            ELSIF (ready='0') THEN 
               next_state <= SWm2;
            ELSE
               next_state <= S23;
            END IF;
         WHEN Scas => 
            IF (hlda='0' OR 
                dma_req_mode0='0') THEN 
               endbuscycle<='1';
               next_state <= Sidle;
            ELSE
               next_state <= Scas;
            END IF;
         WHEN OTHERS =>
            next_state <= Sidle;
      END CASE;
   END PROCESS nextstate_proc;
 
   -- Concurrent Statements
   -- Clocked output assignments
   eop_latched <= eop_latched_cld;
   hrqn_s <= hrqn_s_cld;
   iorn_s <= iorn_s_cld;
   iown_s <= iown_s_cld;
   mem_chan <= mem_chan_cld;
   memrn_s <= memrn_s_cld;
   memwn_s <= memwn_s_cld;
END fsm;
