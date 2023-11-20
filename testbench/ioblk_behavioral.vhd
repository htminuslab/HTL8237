-------------------------------------------------------------------------------
--  HTL8237                                                                  --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : I8237                                                     --
-- Module        : Testbench IO Simulation Module                            --
-- Library       :                                                           --
--                                                                           --
-- Version       : 1.0  20/01/2005   Created HT-LAB                          --
--               : 1.1  20/11/2023   Uploaded to github under MIT license    --  
--                                   checked with Questa/Modelsim 2023.4     --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

USE work.utils.all;

LIBRARY std;
USE std.TEXTIO.all;

ENTITY ioblk IS
   PORT( 
      IOR        : IN     std_logic;
      IOW        : IN     std_logic;
      MEMR       : IN     std_logic;
      MEMW       : IN     std_logic;
      abus       : IN     std_logic_vector (1 DOWNTO 0);
      clk        : IN     std_logic;
      dack2      : IN     std_logic;
      nCS3       : IN     std_logic;
      reset      : IN     std_logic;
      testenable : IN     std_logic;
      testmode   : IN     std_logic_vector (4 DOWNTO 0);
      dreq2      : OUT    std_logic;
      eop        : OUT    std_logic;
      eop_master : OUT    std_logic;
      porta      : OUT    std_logic_vector (7 DOWNTO 0);
      ready      : OUT    std_logic;
      dbus       : INOUT  std_logic_vector (7 DOWNTO 0)
   );
END ioblk ;

ARCHITECTURE behavioral OF ioblk IS

    signal portreg1  : std_logic_vector(7 downto 0);
    signal portreg2  : std_logic_vector(7 downto 0);
    
BEGIN

    process
        constant teststring : STRING (1 to 10):="82C39 TEST";       -- DMA IO Write test
        begin
            dreq2   <= 'L';
            ready   <= '1';
            porta   <=  X"FF";
            dbus    <= (others=>'Z');
            eop     <= 'Z';
            eop_master <= 'Z';
            wait until rising_edge(testenable);
            
            ------------------------------------------------------------------------
            -- Single Transfer Mode
            ------------------------------------------------------------------------
            if (testmode="00001") then
                wait until falling_edge(clk);
                -- Note DREQ2 will remain asserted, the 8237 will stop the transfer
                -- and give control back to the CPU after each transfer
                dreq2<='1';                                          

                
            ------------------------------------------------------------------------
            -- Block Transfer Mode
            -- Once a Block transfer is started, it runs until the transfer count reaches 
            -- zero. DREQ only needs to be asserted until -DACK is asserted. 
            ------------------------------------------------------------------------
            elsif (testmode="00010") then
                wait until falling_edge(clk);
                -- Note DREQ2 will remain asserted, the 8237 will transfer all bytes
                -- until TC
                dreq2<='1';                                          
                wait until falling_edge(dack2);             -- CPU ack DMA request, we can 
                dreq2<='0';                                 -- now remove the request
            
            ------------------------------------------------------------------------
            -- Demand Transfer Mode
            ------------------------------------------------------------------------
            elsif (testmode="00011") then
                wait until falling_edge(clk);
                -- 
                -- 
                dreq2<='1';                                          
                wait until falling_edge(dack2);             -- CPU ack DMA request
                -- We transfer 3 bytes, then we remove the dreq2 for a short delay
                -- We continue were we left off
                wait until rising_edge(IOW);                -- Byte 1 has been transferred
                wait until rising_edge(IOW);                -- Byte 1 has been transferred
                dreq2 <='0';                                -- Wait for some data
                wait for 300 ns;
                dreq2 <='1';                                -- transfer remaining bytes
            
            
            ------------------------------------------------------------------------
            -- Write Single Transfer Mode
            ------------------------------------------------------------------------
            elsif (testmode="00101") then
                wait until falling_edge(clk);
                dreq2<='1';                                          
                wait until falling_edge(dack2);             -- CPU ack DMA request

                for i in 1 to 5 loop
                    wait until falling_edge(IOR);
                    dbus<=to_std_logic_vector(teststring(i));
                    wait until rising_edge(IOR);
                    wait for 5 ns;                          -- Hold time
                    dbus    <= (others=>'Z');
                end loop;
                dreq2<='0';    
                
                
            ------------------------------------------------------------------------
            -- Test Ready READ using Demand Transfer Mode
            -- The memory requires waitstates and asserts READY during S3/S4
            ------------------------------------------------------------------------
            elsif (testmode="00110") then
                wait until falling_edge(clk);
                dreq2<='1';                                          
                wait until falling_edge(dack2);             -- CPU ack DMA request
                dreq2<='0';                                 -- DREQ can now be removed
            
                wait until falling_edge(MEMR);              -- First Read requires 2 waitstates     
                wait until rising_edge(clk);
                ready <= '0';                               -- Ready is sampled during S3 (falling edge clk)
                wait until falling_edge(clk);               -- Introduce 2 waitstates
                wait until falling_edge(clk);   
                wait for 10 ns;                 
                ready <= '1';
                
                wait until falling_edge(MEMR);              -- First Read requires 2 waitstates     
                wait until rising_edge(clk);
                ready <= '0';                               -- Ready is sampled during S3 (falling edge clk)
                wait until falling_edge(clk);               -- Introduce 1 waitstates   
                wait for 10 ns;                 
                ready <= '1';
    
            ------------------------------------------------------------------------
            -- Test Ready Write using Demand Transfer Mode
            ------------------------------------------------------------------------
            elsif (testmode="00111") then
                wait until falling_edge(clk);
                dreq2<='1';                                          
                wait until falling_edge(dack2);             -- CPU ack DMA request
                dreq2<='0';                                 -- DREQ can now be removed
            
                wait until falling_edge(IOR);               -- First Read requires 2 waitstates 
                dbus<=to_std_logic_vector(teststring(1));
                wait until rising_edge(clk);
                ready <= '0';                               -- Ready is sampled during S3 (falling edge clk)
                wait until falling_edge(clk);               -- Introduce 2 waitstates
                wait until falling_edge(clk);
                wait for 5 ns;              
                ready <= '1';
                wait until rising_edge(IOR);
                wait for 5 ns;                              -- Hold time
                dbus    <= (others=>'Z');

    
                wait until falling_edge(IOR);               -- First Read requires 2 waitstates 
                dbus<=to_std_logic_vector(teststring(2));
                wait until rising_edge(clk);
                ready <= '0';                               -- Ready is sampled during S3 (falling edge clk)
                wait until falling_edge(clk);               -- Introduce 1 waitstate
                wait for 5 ns;
                ready <= '1';
                wait until rising_edge(IOR);
                wait for 5 ns;                              -- Hold time
                dbus    <= (others=>'Z');
    
    
            -----------------------------------------------------------------------
            -- Test Ready READ using Demand Transfer Mode
            -- The IO requires a write delay and asserts ready before end of S4
            ------------------------------------------------------------------------
            elsif (testmode="01000") then
                wait until falling_edge(clk);
                dreq2<='1';                                          
                wait until falling_edge(dack2);             -- CPU ack DMA request
                dreq2<='0';                                 -- DREQ can now be removed
                            
                wait until falling_edge(IOW);               -- Second Write requires 1 waitstates       
                wait for 5 ns;
                ready <= '0';                               -- Ready is sampled during S3 (falling edge clk)
                wait until falling_edge(clk);               -- Introduce 2 waitstates
                wait until falling_edge(clk);
                wait for 5 ns;              
                ready <= '1';
                
                wait until falling_edge(IOW);               -- Second Write requires 1 waitstates       
                wait for 5 ns;
                ready <= '0';                               -- Ready is sampled during S3 (falling edge clk)
                wait until falling_edge(clk);               -- Introduce 1 waitstate
                wait for 5 ns;              
                ready <= '1';   
    
            -----------------------------------------------------------------------
            -- Test Ready READ using Demand Transfer Mode
            -- The IO requires a read delay and asserts ready before end of S4
            ------------------------------------------------------------------------
            elsif (testmode="01001") then
                wait until falling_edge(clk);
                dreq2<='1';                                          
                wait until falling_edge(dack2);             -- CPU ack DMA request
                dreq2<='0';                                 -- DREQ can now be removed
                            
                wait until falling_edge(IOR);               -- First I/O Read requires 2 waitstates
                dbus<=to_std_logic_vector(teststring(3));               
                wait for 5 ns;
                ready <= '0';                               -- Ready is sampled end of S4 (falling edge clk)
                wait until falling_edge(clk);               -- Introduce 2 waitstates
                wait until falling_edge(clk);
                wait for 5 ns;              
                ready <= '1';
                wait until rising_edge(IOR);
                wait for 5 ns;                              -- Hold time
                dbus    <= (others=>'Z');
                
                wait until falling_edge(IOR);               -- Second I/O Read requires 1 waitstates    
                dbus<=to_std_logic_vector(teststring(4));               
                wait for 5 ns;
                ready <= '0';                               -- Ready is sampled end of S4 (falling edge clk)
                wait until falling_edge(clk);               -- Introduce ` waitstate
                wait for 5 ns;              
                ready <= '1';   
                wait until rising_edge(IOR);
                wait for 5 ns;                              -- Hold time
                dbus    <= (others=>'Z');
    
    
            -----------------------------------------------------------------------
            -- Test EOP input using READ Demand Transfer Mode
            -- EOP is sampled and latched during S2, checked during S4
            ------------------------------------------------------------------------
            elsif (testmode="01010") then
                wait until falling_edge(clk);
                dreq2<='1';                                          
                wait until falling_edge(dack2);             -- CPU ack DMA request
                dreq2<='0';                                 -- DREQ can now be removed
                            
                wait until falling_edge(IOW);                
                wait until falling_edge(IOW);               -- terminate after second transfer       
                    
                eop <= '0';                                 -- Assert during transfer               
                wait until rising_edge(IOW);
                wait for 5 ns; 
                eop <= 'Z'; 

            -----------------------------------------------------------------------
            -- Test Master EOP input using READ Demand Transfer Mode
            -- The EOP is ignore when controller is in Cascade mode
            ------------------------------------------------------------------------
            elsif (testmode="01011") then
                wait until falling_edge(clk);
                dreq2<='1';                                          
                wait until falling_edge(dack2);             -- CPU ack DMA request
                dreq2<='0';                                 -- DREQ can now be removed
                            
                wait until falling_edge(IOW);                
                wait until falling_edge(IOW);                        
                    
                eop_master <= '0';                          -- Assert during transfer, ignored              
                wait until falling_edge(IOW);
                wait for 5 ns; 
                eop_master <= 'Z';                  
                
            -----------------------------------------------------------------------
            -- Test Memory to Memory transfer Ready input during Verify mode.
            -- The ready signal should be ignored
            ------------------------------------------------------------------------
            elsif (testmode="01101") then               
                ready <= '0';                               -- Continuously asserted (ignored)                      

            end if;

            wait until falling_edge(testenable);
                
    end process;
    
    
    process(clk,reset)
        variable L   : line;
        begin
            if reset='1' then
                portreg1<=X"2A";
                portreg2<=X"55";                
            elsif rising_edge(clk) then
                if (nCS3='0' and IOW='0') then
                    if abus(0)='0' then
                        portreg1<=dbus;
                    else
                        portreg2<=dbus;
                    end if;
                elsif (dack2='0' and IOW='0' and testenable='1') then
                    portreg1<=dbus;      
                    write(L,string'("   IO DMA Write channel 2 ")); 
                    write(L,std_to_char(dbus));
                    writeline(output,L);  
                elsif (dack2='0' and IOR='0' and testenable='1') then    
                    write(L,string'("   IO DMA Read channel 2 ")); 
                    writeline(output,L); 
                end if;
            end if;
    end process;
    

END ARCHITECTURE behavioral;

