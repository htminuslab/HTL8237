-------------------------------------------------------------------------------
--  HTL8237                                                                  --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : I8237                                                     --
-- Module        : Testbench Tester Module                                   --
-- Library       :                                                           --
--                                                                           --
-- Version       : 1.0  20/01/2005   Created HT-LAB                          --
--               : 1.1  26/01/2014   Updated/cleaned up                      -- 
--               : 1.2  30/11/2023   Uploaded to github under MIT license    --  
--                                   checked with Questa/Modelsim 2023.4     --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

USE work.utils.all;

LIBRARY std;
USE std.TEXTIO.all;

ENTITY stimulus IS
   PORT( 
      aen        : IN     std_logic;
      clk        : IN     std_logic;
      dack       : IN     std_logic_vector (3 DOWNTO 0);
      dreq2      : IN     std_logic;
      hrq        : IN     std_logic;
      abus       : OUT    std_logic_vector (19 DOWNTO 0);
      ale        : OUT    std_logic;
      dack2      : OUT    std_logic;
      dreq       : OUT    std_logic_vector (3 DOWNTO 0);
      mio        : OUT    std_logic;
      reset      : OUT    std_logic;
      testcount  : OUT    integer;
      testenable : OUT    std_logic;
      testmode   : OUT    std_logic_vector (4 DOWNTO 0);
      IOR        : INOUT  std_logic;
      IOW        : INOUT  std_logic;
      MEMR       : INOUT  std_logic;
      MEMW       : INOUT  std_logic;
      dbus       : INOUT  std_logic_vector (7 DOWNTO 0);
      eop        : INOUT  std_logic;
      hlda       : BUFFER std_logic
   );
END stimulus ;


ARCHITECTURE behavioral OF stimulus IS

    signal   data_s  : std_logic_vector(7 downto 0);
    signal   data16_s: std_logic_vector(15 downto 0);
             
    signal   dbus_in : std_logic_vector(7 downto 0);
    signal   dbus_out: std_logic_vector(7 downto 0);
    signal   wrdbus  : std_logic;

    signal   eop_s   : std_logic;
    signal   eop0_s  : std_logic;
    signal   eop1_s  : std_logic;
    signal   eop2_s  : std_logic;
    signal   eop3_s  : std_logic;
    
    constant MASTER_MODE_REGISTER_C     : std_logic_vector(15 downto 0) := X"00CB";
    constant MASTER_MASK_REGISTER_C     : std_logic_vector(15 downto 0) := X"00CF";
    constant MASTER_COMMAND_REGISTER_C  : std_logic_vector(15 downto 0) := X"00C8";
    
    constant BASE_ADDRESS0_C    : std_logic_vector(15 downto 0) := X"0000";
    constant CURR_ADDRESS0_C    : std_logic_vector(15 downto 0) := X"0000";
    constant BASE_COUNT0_C      : std_logic_vector(15 downto 0) := X"0001";
    constant CURR_COUNT0_C      : std_logic_vector(15 downto 0) := X"0001"; 
    
    constant BASE_ADDRESS1_C    : std_logic_vector(15 downto 0) := X"0002";
    constant CURR_ADDRESS1_C    : std_logic_vector(15 downto 0) := X"0002";
    constant BASE_COUNT1_C      : std_logic_vector(15 downto 0) := X"0003";
    constant CURR_COUNT1_C      : std_logic_vector(15 downto 0) := X"0003"; 
    
    constant BASE_ADDRESS2_C    : std_logic_vector(15 downto 0) := X"0004";
    constant CURR_ADDRESS2_C    : std_logic_vector(15 downto 0) := X"0004";
    constant BASE_COUNT2_C      : std_logic_vector(15 downto 0) := X"0005";
    constant CURR_COUNT2_C      : std_logic_vector(15 downto 0) := X"0005"; 
    
    constant BASE_ADDRESS3_C    : std_logic_vector(15 downto 0) := X"0006";
    constant CURR_ADDRESS3_C    : std_logic_vector(15 downto 0) := X"0006";
    constant BASE_COUNT3_C      : std_logic_vector(15 downto 0) := X"0007";
    constant CURR_COUNT3_C      : std_logic_vector(15 downto 0) := X"0007";     
    
    constant MASK_REGISTER_C    : std_logic_vector(15 downto 0) := X"000F";
    constant CLR_MODE_CNT       : std_logic_vector(15 downto 0) := X"000E";
    constant TEMP_REGISTER_C    : std_logic_vector(15 downto 0) := X"000D";
    constant FIRST_LAST_FF_C    : std_logic_vector(15 downto 0) := X"000C";
    constant MODE_REGISTER_C    : std_logic_vector(15 downto 0) := X"000B";
    constant READ_CMD_REGISTER_C: std_logic_vector(15 downto 0) := X"000A";
    constant REQUEST_REGISTER_C : std_logic_vector(15 downto 0) := X"0009";
    constant COMMAND_REGISTER_C : std_logic_vector(15 downto 0) := X"0008";
    constant STATUS_REGISTER_C  : std_logic_vector(15 downto 0) := X"0008";
    
    constant PAGE0_REGISTER_C   : std_logic_vector(15 downto 0) := X"0087";-- r/w Channel 0 Low byte (23-16) page Register
    constant PAGE1_REGISTER_C   : std_logic_vector(15 downto 0) := X"0083";-- r/w Channel 1 Low byte (23-16) page Register
    constant PAGE2_REGISTER_C   : std_logic_vector(15 downto 0) := X"0081";-- r/w Channel 2 Low byte (23-16) page Register
    constant PAGE3_REGISTER_C   : std_logic_vector(15 downto 0) := X"0082";-- r/w Channel 3 Low byte (23-16) page Register  
    
    
BEGIN
    
    wrdbus <= '1' when (IOW='0' AND hlda='0') else '0';                  
         
    dreq(2) <= dreq2;
    dack2   <= dack(2);
         
    process (wrdbus,dbus_out)
       begin  
        case wrdbus is
            when '1'    => dbus<= dbus_out after 10 ns;                 -- drive 
            when '0'    => dbus<= (others => 'Z') after 10 ns;
            when others => dbus<= (others => 'X') after 10 ns;         
        end case;    
    end process;   
    dbus_in <= dbus;                                                    -- drive internal dbus 
    

    -----------------------------------------------------------------------------------------------
    -- Monitor EOP signals
    -- Write string to console
    ----------------------------------------------------------------------------------------------- 
    process (clk)
        variable L   : line;
        begin 
            --if rising_edge(clk) then
            if falling_edge(clk) then
                if EOP='0' then
                    eop_s <= '1';
                    case DACK is
                        when "1110" => write(L,string'(" EOP Asserted Channel 0")); eop0_s<='1';
                        when "1101" => write(L,string'(" EOP Asserted Channel 1")); eop1_s<='1';
                        when "1011" => write(L,string'(" EOP Asserted Channel 2")); eop2_s<='1';
                        when "0111" => write(L,string'(" EOP Asserted Channel 3")); eop3_s<='1';
                        when others => if (aen='1') then
                                           write(L,string'(" EOP Memory to Memory Transfer"));eop1_s<='1';
                                       else
                                           write(L,string'(""));                                       
                                           report " Spurious EOP Detected";
                                       end if;
                    end case;
                    writeline(output,L);
                else
                    eop_s <='0';
                    eop0_s<='0';
                    eop1_s<='0';
                    eop2_s<='0';
                    eop3_s<='0';
                end if;         
            end if;
    end process;
    
    -----------------------------------------------------------------------------------------------
    -- Monitor DACK (active low) signals
    -- Write string to console
    -----------------------------------------------------------------------------------------------
    process (DACK)
        variable L   : line;
        begin 
            if falling_edge(DACK(0)) then
                write(L,string'(" DACK0 Asserted"));
                writeline(output,L);            
            end if;
            if falling_edge(DACK(1)) then
                write(L,string'(" DACK1 Asserted"));
                writeline(output,L);            
            end if;
            if falling_edge(DACK(2)) then
                write(L,string'(" DACK2 Asserted"));
                writeline(output,L);            
            end if;
            if falling_edge(DACK(3)) then
                write(L,string'(" DACK3 Asserted"));
                writeline(output,L);            
            end if;         
    end process;
    
    
    process
        variable L   : line;

        ----------------------------------------------------------------------------------------------- 
        -- Dump Memory to console.
        -- Example: dump_memory(X"10000",X"10020");
        -- # 10000 : 48 65 6C 6C 6F 20 57 6F 72 6C 64 00 00 00 00 00 
        -- # 10010 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
        -- # 10020 : 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
        ----------------------------------------------------------------------------------------------- 
        procedure dump_memory(                                                
            constant startaddr_p : in std_logic_vector(19 downto 0);            -- Start Address
            constant endaddr_p   : in std_logic_vector(19 downto 0)) is 
                variable address_v : unsigned(19 downto 0);             
            begin 
                address_v:=unsigned(startaddr_p);
                
              --write(L,string'("        00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F"));
              --writeline(output,L); 
                loop
                    write(L,std_to_hex(std_logic_vector(address_v)));
                    write(L,string'(" : "));                    
                    MEMR  <= '1';
                    for n in 0 to 15 loop
                        wait until rising_edge(clk);                    
                        abus <= std_logic_vector(address_v + n);            -- 20 bits Address bus
                        mio  <= '1';                                        -- Select memory
                        wait for 30 ns;                 
                        ale  <='0';                 
                        wait until falling_edge(clk);                       -- Start of T2
                        MEMR  <= '0';   
                        wait until falling_edge(clk);                   
                        write(L,std_to_hex(dbus));  
                        write(L,string'(" "));                          
                        MEMR  <= '1';
                        wait until rising_edge(clk);                    
                    end loop;
                    writeline(output,L);
                    if (address_v < unsigned(endaddr_p)) then
                        address_v:=address_v+16;
                    else
                        exit;
                    end if;
                end loop;               
        end dump_memory;
    
        
        ----------------------------------------------------------------------------------------------- 
        -- Simulate 8086 Write to IO Port
        ----------------------------------------------------------------------------------------------- 
        procedure outport(                                              -- write byte to I/O port using clk  
            constant addr_p : in std_logic_vector(15 downto 0);         -- Port Address (only lower byte)
            constant dbus_p : in std_logic_vector(7 downto 0)) is 
            begin 
                wait until falling_edge(clk);                           -- Start of T1
                ale<='1';                   
                wait until rising_edge(clk);                    
                abus <= X"0"&addr_p;                                    -- 20 bits Address bus
                mio  <= '0';                                            -- Select I/O
                wait for 30 ns;                 
                ale  <='0';                 
                wait until falling_edge(clk);                           -- Start of T2
                iow  <= '0';                    
                dbus_out <= (others => 'Z');                    
                wait until rising_edge(clk);                    
                dbus_out <= dbus_p;                                         -- Drive Databus
                wait until falling_edge(clk);                           -- Start of T3
                wait until falling_edge(clk);                           -- Start of T4
                wait for 30 ns;                 
                iow  <= '1';                    
                wait for 20 ns;                 
                dbus_out <= (others => 'Z');                    
                wait until falling_edge(clk);                           -- Start of T1
                abus <= "HHHHHHHHHHHHHHHHHHHH";
                mio  <= '1';
        end outport;

        ----------------------------------------------------------------------------------------------- 
        -- Simulate 8086 Read from IO Port
        ----------------------------------------------------------------------------------------------- 
         procedure inport(                                              -- Read from I/O port   
            constant addr_p : in std_logic_vector(15 downto 0);         -- Port Address
            signal dbus_p : out std_logic_vector(7 downto 0)) is 
            begin 
                wait until falling_edge(clk);                           -- Start of T1
                ale<='1';                   
                wait until rising_edge(clk);                    
                abus <= X"0"&addr_p;                                    -- 20 bits Address bus
                mio  <= '0';                                            -- Select I/O   
                wait for 30 ns;                 
                ale  <= '0';                    
                wait until falling_edge(clk);                           -- Start of T2
                wait until rising_edge(clk);                    
                ior  <= '0';                    
                wait until falling_edge(clk);                           -- Start of T3
                --iorn <= '0';                  
                dbus_p <= dbus_in;                  
                wait until falling_edge(clk);                           -- Start of T4
                wait for 20 ns;                 
                ior  <= '1';                    
                wait until falling_edge(clk);                           -- Start of T1
                abus <= "HHHHHHHHHHHHHHHHHHHH";
                mio  <= '1';          
        end inport;

        ----------------------------------------------------------------------------------------------- 
        -- Display 8237 internal registers
        ----------------------------------------------------------------------------------------------- 
        procedure disp_status is                                        -- Display Address/Count Status registers
            begin 

                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF      
            
                write(L,string'(" CH0:A="));            
                inport(CURR_ADDRESS0_C,data16_s(7 downto 0));           -- Current address 
                inport(CURR_ADDRESS0_C,data16_s(15 downto 8));          
                write(L,std_to_hex(data16_s));          
                            
                write(L,string'(" C="));            
                inport(CURR_COUNT0_C,data16_s(7 downto 0));             -- Current Count address
                inport(CURR_COUNT0_C,data16_s(15 downto 8));            
                write(L,std_to_hex(data16_s));          
            
            
                write(L,string'("  CH1:A="));               
                inport(CURR_ADDRESS1_C,data16_s(7 downto 0));           -- Current address 
                inport(CURR_ADDRESS1_C,data16_s(15 downto 8));          
                write(L,std_to_hex(data16_s));          
                            
                write(L,string'(" C="));            
                inport(CURR_COUNT1_C,data16_s(7 downto 0));             -- Current Count address
                inport(CURR_COUNT1_C,data16_s(15 downto 8));
                write(L,std_to_hex(data16_s));


                write(L,string'("  CH2:A="));   
                inport(CURR_ADDRESS2_C,data16_s(7 downto 0));           -- Current address 
                inport(CURR_ADDRESS2_C,data16_s(15 downto 8));          
                write(L,std_to_hex(data16_s));          
                            
                write(L,string'(" C="));            
                inport(CURR_COUNT2_C,data16_s(7 downto 0));             -- Current Count address
                inport(CURR_COUNT2_C,data16_s(15 downto 8));            
                write(L,std_to_hex(data16_s));          
            
                write(L,string'("  CH3:A="));               
                inport(CURR_ADDRESS3_C,data16_s(7 downto 0));           -- Current address 
                inport(CURR_ADDRESS3_C,data16_s(15 downto 8));          
                write(L,std_to_hex(data16_s));          
                            
                write(L,string'(" C="));            
                inport(CURR_COUNT3_C,data16_s(7 downto 0));             -- Current Count address
                inport(CURR_COUNT3_C,data16_s(15 downto 8));
                write(L,std_to_hex(data16_s));

                writeline(output,L);

                ---------------------------------------------------------------------------
                -- Read Mode Registers
                -- First issue CLR_MODE_CNT command
                ---------------------------------------------------------------------------
                data_s <= "--------";
                inport(CLR_MODE_CNT,data_s);                            -- Clear Mode Counter
                
                for n in 0 to 3 loop
                    write(L,string'(" MD"));                            -- Display Mode Register
                    write(L,integer'(n)); 
                    inport(MODE_REGISTER_C,data_s);
                    wait for 0 ns;
                    case data_s(7 downto 6) is
                        when "00"   => write(L,string'(":D,")); 
                        when "01"   => write(L,string'(":S,")); 
                        when "10"   => write(L,string'(":B,")); 
                        when others => write(L,string'(":C,")); 
                    end case;
                    if data_s(5)='0' then write(L,string'("A++,")); 
                                     else write(L,string'("A--,"));
                    end if; 
                    if data_s(4)='1' then write(L,string'("AI,"));
                                     else write(L,string'("  ,")); 
                    end if; 
                    case data_s(3 downto 2) is
                        when "00"   => write(L,string'("VF   ")); 
                        when "01"   => write(L,string'("WR   ")); 
                        when "10"   => write(L,string'("RD   ")); 
                        when others => if data_s(7 downto 6)="11" then
                                           assert FALSE report "Illegal Value in Mode Register" severity warning;
                                       end if;
                    end case;
                end loop;
                writeline(output,L);

                write(L,string'(" Status="));                           -- Display Status Register
                inport(STATUS_REGISTER_C,data_s);
                write(L,std_to_hex(data_s));
                
                write(L,string'(" Mask="));                             -- Display Mask Bits
                inport(MASK_REGISTER_C,data_s);
                write(L,std_to_hex(data_s(3 downto 0)));

                write(L,string'(" Request="));                          -- Display Request
                inport(REQUEST_REGISTER_C,data_s);
                write(L,std_to_hex(data_s(3 downto 0)));

                write(L,string'(" Command="));                          -- Display Command Register
                inport(READ_CMD_REGISTER_C,data_s);
                write(L,std_to_hex(data_s));

                write(L,string'(" Temp="));                             -- Display Temp Register
                inport(TEMP_REGISTER_C,data_s);
                write(L,std_to_hex(data_s));

                inport(READ_CMD_REGISTER_C,data_s);                     -- Read Command Register
                if data_s(0)='1' then write(L,string'(" MEM2MEM")); 
                end if; 
                if data_s(1)='1' then write(L,string'(" CH0Hold")); 
                end if; 
                if data_s(3)='1' then write(L,string'(" Compressed Timing")); 
                end if; 
                if data_s(4)='1' then write(L,string'(" Rotate Priority")); 
                end if; 
                if data_s(5)='1' then write(L,string'(" Extended Write")); 
                end if; 
                writeline(output,L);

        end disp_status;

        ----------------------------------------------------------------------------------------------- 
        -- Main Stimulus
        -- Test is indicated my the "testmode" value. Each test is further divided into "n" sub tests.  
        -----------------------------------------------------------------------------------------------         
        begin
           
            testenable <= '0';                                          -- Test/DMA IOPort disable
            testmode <= (others => '0');                                -- IOPort Test Mode
            testcount<= 0;                                              -- Number of bytes to transfer

            dbus_out <= (others => 'H');
            abus     <= (others => 'H');
            ale      <= '0';
            reset    <= '1';
            
            iow      <= '1';
            ior      <= '1';
            MEMW     <= '1';
            MEMR     <= '1';
            hlda     <= '0';
            dreq     <= (others => 'L');
            
            eop      <= 'H';

            wait for 167 ns;
            reset    <= '0';
            wait for 100 ns;

            
            --=========================================================================
            -- Initialise Master (1st level) 82C39 in Cascade mode. The Slave (second 
            -- level) is connected to the Master's Channel0.
            -- Active low chipselect nCS4 is used for the Master controller
            --=========================================================================
            write(L,string'(" ======================= Init Master 8239 ==================================== "));   
            writeline(output,L);
            
            outport(MASTER_MASK_REGISTER_C,"----1111");                 -- Disable all channels
            outport(MASTER_COMMAND_REGISTER_C,"10000000");              -- DACK active high
            outport(MASTER_MODE_REGISTER_C,"11000000");                 -- Cascade mode channel0
            outport(MASTER_MASK_REGISTER_C,"----1110");                 -- Enable channel0
                    
        
            --=========================================================================
            -- Single IO Read Transfer 
            --
            -- This mode transfer a single byte (or word). The 8238 DMA controller will 
            -- release and re-acquire the cpu bus for each additional byte. This mode is 
            -- commonly-used by devices that cannot transfer the entire block of data in
            -- one go. The peripheral will request the DMA each time it is ready for 
            -- another transfer. 
            --
            --  Test  Action
            --    0   Addr++, 5 bytes, address 10000-10004 
            --    1   Addr++, 5 bytes, address 10000-10004, AutoInit
            --    2   Addr--, 5 bytes, address 10004-10000, Extended write
            --    3   Addr--, 5 bytes, address 10004-10000, Compressed timing, Autoinit
            --    4   Addr++, 5 bytes, address 10000-10004, Verify transfer
            --=========================================================================
            write(L,string'(" ======================= Single Transfer Read Test =========================== "));   
            writeline(output,L);
           
            for n in 0 to 4 loop
                                                                 
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 
    
                ---------------------------------------------------------------------------
                -- Set-up Page Registers Channel 2
                -- 0x87    r/w    Channel 0 Low byte (23-16) page Register
                -- 0x83    r/w    Channel 1 Low byte (23-16) page Register
                -- 0x81    r/w    Channel 2 Low byte (23-16) page Register
                -- 0x82    r/w    Channel 3 Low byte (23-16) page Register                              
                ---------------------------------------------------------------------------                                  
                outport(PAGE2_REGISTER_C,"----0001");                   -- Program Page Channel 2
                
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                ---------------------------------------------------------------------------                      
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 
                                    
                if n=0 OR n=1 then 
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS LSB
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS MSB
                else
                    outport(BASE_ADDRESS2_C,X"04");                     -- Ch2 Base and Current ADDRESS LSB
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS MSB
                end if;
                                        
                outport(BASE_COUNT2_C,X"04");                           -- Ch2 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT2_C,X"00");                           -- Ch2 Base and Current COUNT MSB
                testcount<=5;
    
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Single Transfer 
                -- Write transfer means WRITE to memory read from IO
                -- Read  transfer means READ from memory write to IO
                ---------------------------------------------------------------------------
                if (n=0) then           
                    outport(MODE_REGISTER_C,"01001010");                -- CH2 Single, Addr++, READ
                elsif (n=1) then            
                    outport(MODE_REGISTER_C,"01011010");                -- CH2 Single, AutoInit, Addr++, READ
                elsif (n=2) then            
                    outport(MODE_REGISTER_C,"01101010");                -- CH2 Single, Addr--, READ
                elsif (n=3) then            
                    outport(MODE_REGISTER_C,"01101010");                -- CH2 Single, AutoInit, Addr--, READ
                else                
                    outport(MODE_REGISTER_C,"01000010");                -- CH2 Single, Verify transfer, Addr++
                end if;
    
                ---------------------------------------------------------------------------
                -- Issue command
                ---------------------------------------------------------------------------
                if (n=1) then           
                    outport(COMMAND_REGISTER_C,"00000000");             -- Normal Write
                elsif (n=2) then                            
                    outport(COMMAND_REGISTER_C,"00100000");             -- Extended Write
                elsif (n=3) then            
                    outport(COMMAND_REGISTER_C,"00001000");             -- Compressed Timing
                else 
                    outport(COMMAND_REGISTER_C,"00000000");             -- Normal Write
                end if;
                    
                ---------------------------------------------------------------------------
                -- Unmask Channel 2 only
                ---------------------------------------------------------------------------                         
                outport(MASK_REGISTER_C,"00001011");                    -- Enable CH2 
    
    
                write(L,string'(" ----------- HTL8237 status before memory to IO transfer -------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
            
                ---------------------------------------------------------------------------
                -- Enable TestIO controller
                -- Mode 0001  IOW with Single DREQ 
                ---------------------------------------------------------------------------
                testenable <= '1';                                      -- Enable DMA Request
                testmode   <= "00001";                                  -- Single transfer
                
                
                if (n=0) then
                    write(L,string'(" Start DMA Test 0 Addr++, 5 bytes, address 10000-10004"));
                elsif (n=1) then
                    write(L,string'(" Start DMA Test 1 Addr++, 5 bytes, address 10000-10004, AutoInit"));
                elsif (n=2) then
                    write(L,string'(" Start DMA Test 2 Addr--, 5 bytes, address 10004-10000, Extended write"));
                elsif (n=3) then
                    write(L,string'(" Start DMA Test 3 Addr--, 5 bytes, address 10004-10000, Compressed timing, Autoinit"));
                else
                    write(L,string'(" Start DMA Test 4 Addr++, 5 bytes, address 10000-10004, Verify transfer"));
                end if;
                writeline(output,L);
   
                --=========================================================================
                -- Start DMA Transfer
                -- HRQ will be asserted
                --=========================================================================
                for n in 1 to testcount loop
                    wait until rising_edge(hrq);                        -- 8237 request the bus
                    wait until falling_edge(clk);
                    wait until falling_edge(clk);
                    wait for 10 ns;                                     -- Tclhav 10-160 ns, Regain the bus
                    hlda <= '1';                                        -- CPU Releases the bus
                    abus     <= (others => 'H');            
                    iow      <= 'H';            
                    ior      <= 'H';            
                    MEMW     <= 'H';            
                    MEMR     <= 'H';
                                
                    wait until falling_edge(hrq);                       -- Wait for 8237 to remove DMA request
                    wait until falling_edge(clk);
                    hlda <= '0';                                        -- CPU takes back the bus
                    abus     <= (others => '1');            
                    iow      <= '1';            
                    ior      <= '1';            
                    MEMW     <= '1';            
                    MEMR     <= '1';    
                    write(L,string'("   CPU has access to the bus"));
                    writeline(output,L);                            
                end loop;
                testenable <= '0';                                      -- end of test
    
                write(L,string'(" ----------- 82C37 status after memory to IO transfer ---------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All

                write(L,string'(""));                                   -- Newline
                writeline(output,L);
                
                wait for 100 ns;
            end loop;   
                    
            --=========================================================================
            -- Single IO Write Transfer 
            --
            -- This mode transfer a single byte (or word). The 8238 DMA controller will 
            -- release and re-acquire the cpu bus for each additional byte. This mode is 
            -- commonly-used by devices that cannot transfer the entire block of data in
            -- one go. The peripheral will request the DMA each time it is ready for 
            -- another transfer. 
            --
            --  Test  Action
            --    0   Addr++, 5 bytes, address 80100-80104 
            --    1   Addr++, 5 bytes, address 80100-80104, AutoInit
            --    2   Addr--, 5 bytes, address 80110-80114, Extended write
            --    3   Addr--, 5 bytes, address 80120-80124, Compressed timing, Autoinit
            --=========================================================================
            write(L,string'(" ======================= Single Transfer Write Test ========================== "));   
            writeline(output,L);
            
            dump_memory(X"80100",X"80120");                             -- Show memory before transfer
           
            for n in 0 to 3 loop
                                                                 
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 
    
                ---------------------------------------------------------------------------
                -- Set-up Page Registers Channel 2                         
                ---------------------------------------------------------------------------                                  
                outport(PAGE2_REGISTER_C,"----1000");                   -- Program Page Channel 2
                
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                ---------------------------------------------------------------------------                      
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 
                                    
                if n=0 OR n=1 then 
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS LSB
                    outport(BASE_ADDRESS2_C,X"01");                     -- Ch2 Base and Current ADDRESS MSB
                elsif (n=2) then
                    outport(BASE_ADDRESS2_C,X"10");                     -- Ch2 Base and Current ADDRESS LSB
                    outport(BASE_ADDRESS2_C,X"01");                     -- Ch2 Base and Current ADDRESS MSB
                else 
                    outport(BASE_ADDRESS2_C,X"20");                     -- Ch2 Base and Current ADDRESS LSB
                    outport(BASE_ADDRESS2_C,X"01");                     -- Ch2 Base and Current ADDRESS MSB
                end if;
                                        
                outport(BASE_COUNT2_C,X"04");                           -- Ch2 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT2_C,X"00");                           -- Ch2 Base and Current COUNT MSB
                testcount<=5;
    
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Single Transfer 
                -- Write transfer means WRITE to memory read from IO
                -- Read  transfer means READ from memory write to IO
                ---------------------------------------------------------------------------
                if (n=0) then           
                    outport(MODE_REGISTER_C,"01000110");                -- CH2 Single, Addr++, WRITE
                elsif (n=1) then            
                    outport(MODE_REGISTER_C,"01010110");                -- CH2 Single, AutoInit, Addr++, WRITE
                elsif (n=2) then            
                    outport(MODE_REGISTER_C,"01100110");                -- CH2 Single, Addr--, WRITE
                else            
                    outport(MODE_REGISTER_C,"01100110");                -- CH2 Single, AutoInit, Addr--, WRITE
                end if;
    
                ---------------------------------------------------------------------------
                -- Issue command
                ---------------------------------------------------------------------------
                if (n=1) then           
                    outport(COMMAND_REGISTER_C,"00000000");             -- Normal Write
                elsif (n=2) then                            
                    outport(COMMAND_REGISTER_C,"00100000");             -- Extended Write
                elsif (n=3) then            
                    outport(COMMAND_REGISTER_C,"00001000");             -- Compressed Timing
                else 
                    outport(COMMAND_REGISTER_C,"00000000");             -- Normal Write
                end if;
                    
                ---------------------------------------------------------------------------
                -- Unmask Channel 2 only
                ---------------------------------------------------------------------------                         
                outport(MASK_REGISTER_C,"00001011");                    -- Enable CH2 
    
    
                write(L,string'(" ----------- HTL8237 status before memory to IO transfer -------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
            
                ---------------------------------------------------------------------------
                -- Enable TestIO controller
                ---------------------------------------------------------------------------
                testenable <= '1';                                      -- Enable DMA Request
                testmode   <= "00101";                                  -- Single transfer
                
                
                if (n=0) then
                    write(L,string'(" Start DMA Test 0 Addr++, 5 bytes, address 80100-80104"));
                elsif (n=1) then
                    write(L,string'(" Start DMA Test 1 Addr++, 5 bytes, address 80100-80104, AutoInit"));
                elsif (n=2) then
                    write(L,string'(" Start DMA Test 2 Addr--, 5 bytes, address 80110-80110, Extended write"));
                else
                    write(L,string'(" Start DMA Test 3 Addr--, 5 bytes, address 80120-80120, Compressed timing, Autoinit"));
                end if;
                writeline(output,L);
   
                --=========================================================================
                -- Start DMA Transfer
                -- HRQ will be asserted
                --=========================================================================
                for n in 1 to testcount loop
                    wait until rising_edge(hrq);                        -- 8237 request the bus
                    wait until falling_edge(clk);
                    wait until falling_edge(clk);
                    wait for 10 ns;                                     -- Tclhav 10-160 ns, Regain the bus
                    hlda <= '1';                                        -- CPU Releases the bus
                    abus     <= (others => 'H');            
                    iow      <= 'H';            
                    ior      <= 'H';            
                    MEMW     <= 'H';            
                    MEMR     <= 'H';
                    
                    wait until falling_edge(hrq);                       -- Wait for 8237 to remove DMA request
                    wait until falling_edge(clk);
                    hlda <= '0';                                        -- CPU takes back the bus
                    abus     <= (others => '1');            
                    iow      <= '1';            
                    ior      <= '1';            
                    MEMW     <= '1';            
                    MEMR     <= '1';    
                    write(L,string'("   CPU has access to the bus"));
                    writeline(output,L);                            
                end loop;
                testenable <= '0';                                      -- end of test
    
                write(L,string'(" ----------- 82C37 status after memory to IO transfer ---------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All

                write(L,string'(""));                                   -- Newline
                writeline(output,L);
                
                dump_memory(X"80100",X"80120");
                
                wait for 100 ns;
            end loop;   
            
    

            --=========================================================================
            -- Memory Read to IO Write Block Transfer
            --
            -- In Block Transfer mode, the device is activated by DREQ or software request 
            -- and continues making transfers during the service until a TC, caused by
            -- word count going to FFFFH, or an external End of Process (EOP) is encountered. 
            -- DREQ need only be held active until DACK becomes active. Again, an Auto-
            -- initialization will occur at the end of the service if the channel has been  
            -- programmed for that option.
            --
            --  Test  Action
            --    0   Addr++, 5 bytes, address 10000-10004 
            --    1   Addr++, 5 bytes, address 10000-10004, AutoInit
            --    2   Addr--, 5 bytes, address 10004-10000, Extended write
            --    3   Addr--, 5 bytes, address 10004-10000, Compressed timing, Autoinit
            --=========================================================================
            write(L,string'(" ======================= Block Read Transfer Test ============================ "));   
            writeline(output,L);
                       
            for n in 0 to 3 loop
                                                                 
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 
    
                ---------------------------------------------------------------------------
                -- Set-up Page Registers Channel 2
                -- 0x87    r/w    Channel 0 Low byte (23-16) page Register
                -- 0x83    r/w    Channel 1 Low byte (23-16) page Register
                -- 0x81    r/w    Channel 2 Low byte (23-16) page Register
                -- 0x82    r/w    Channel 3 Low byte (23-16) page Register                              
                ---------------------------------------------------------------------------                                  
                outport(PAGE2_REGISTER_C,"----0001");                   -- Program Page Channel 2
                
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                ---------------------------------------------------------------------------                      
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 
                                    
                if n=0 OR n=1 then 
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS LSB
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS MSB
                else
                    outport(BASE_ADDRESS2_C,X"04");                     -- Ch2 Base and Current ADDRESS LSB
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS MSB
                end if;
                                        
                outport(BASE_COUNT2_C,X"04");                           -- Ch2 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT2_C,X"00");                           -- Ch2 Base and Current COUNT MSB
                testcount<=5;
    
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Block Transfer 
                -- Write transfer means WRITE to memory read from IO
                -- Read  transfer means READ from memory write to IO
                ---------------------------------------------------------------------------
                if (n=0) then           
                    outport(MODE_REGISTER_C,"10001010");                -- CH2 Block, Addr++, READ
                elsif (n=1) then            
                    outport(MODE_REGISTER_C,"10011010");                -- CH2 Block, AutoInit, Addr++, READ
                elsif (n=2) then            
                    outport(MODE_REGISTER_C,"10101010");                -- CH2 Block, Addr--, READ
                else                
                    outport(MODE_REGISTER_C,"10111010");                -- CH2 Block, AutoInit, Addr--, READ
                end if;
    
                ---------------------------------------------------------------------------
                -- Issue command
                ---------------------------------------------------------------------------
                if (n=0) then           
                    outport(COMMAND_REGISTER_C,"00000000");             -- Normal Write
                elsif (n=1) then            
                    outport(COMMAND_REGISTER_C,"00000000");             -- Normal Write
                elsif (n=2) then                            
                    outport(COMMAND_REGISTER_C,"00100000");             -- Extended Write
                else            
                    outport(COMMAND_REGISTER_C,"00001000");             -- Compressed Timing
                end if;
                    
                ---------------------------------------------------------------------------
                -- Unmask Channel 2 only
                ---------------------------------------------------------------------------                         
                outport(MASK_REGISTER_C,"00001011");                    -- Enable CH2 
    
    
                write(L,string'(" ----------- HTL8237 status before memory to IO transfer -------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
            
                ---------------------------------------------------------------------------
                -- Enable TestIO controller
                -- Mode 0001  IOW with Single DREQ 
                ---------------------------------------------------------------------------             
                testenable <= '1';                                      -- Enable DMA Request
                testmode   <= "00010";                                  -- Block transfer
                                
                if (n=0) then
                    write(L,string'(" Start DMA Test 0 Addr++, 5 bytes, address 10000-10004"));
                elsif (n=1) then
                    write(L,string'(" Start DMA Test 1 Addr++, 5 bytes, address 10000-10004, AutoInit"));
                elsif (n=2) then
                    write(L,string'(" Start DMA Test 2 Addr--, 5 bytes, address 10004-10000, Extended write"));
                else 
                    write(L,string'(" Start DMA Test 3 Addr--, 5 bytes, address 10004-10000, Compressed timing, Autoinit"));
                end if;
                writeline(output,L);
   
                --=========================================================================
                -- Start Block DMA Transfer
                --=========================================================================
                wait until rising_edge(hrq);                            -- 8237 request the bus
                wait until falling_edge(clk);
                wait until falling_edge(clk);
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda <= '1';                                            -- CPU Releases the bus
                abus     <= (others => 'H');            
                iow      <= 'H';            
                ior      <= 'H';            
                MEMW     <= 'H';            
                MEMR     <= 'H';
                                            
                wait until falling_edge(hrq);                           -- Wait for 8237 to remove DMA request
                wait until falling_edge(clk);
                hlda <= '0';                                            -- CPU takes back the bus
                abus     <= (others => '1');            
                iow      <= '1';            
                ior      <= '1';            
                MEMW     <= '1';            
                MEMR     <= '1';    
                write(L,string'("   CPU has access to the bus"));
                writeline(output,L);                            

                testenable <= '0';                                      -- end of test
    
                write(L,string'(" ----------- 82C37 status after memory to IO transfer ---------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All

                write(L,string'(""));                                   -- Newline
                writeline(output,L);
                
                wait for 100 ns;
            end loop;
            
            
            --=========================================================================
            -- Memory Read to IO Write Demand Block Transfer
            --
            -- Demand Mode will transfer data until DREQ is de-asserted, TC or an external 
            -- EOP is detected. When DREQ is re-asserted the transfer resumes where it 
            -- was suspended. 
            -- Only an EOP can cause an Autoinitialization at the end of service. EOP is
            -- generated by TC or an external signal
            --
            --  Test  Action
            --    0   Addr++, 5 bytes, address 10000-10004 
            --    1   Addr++, 5 bytes, address 10000-10004, AutoInit
            --    2   Addr--, 5 bytes, address 10004-10000, Extended write
            --    3   Addr--, 5 bytes, address 10004-10000, Compressed timing, Autoinit
            --=========================================================================
            write(L,string'(" ======================= Demand Transfer Test ================================ "));   
            writeline(output,L);
                       
            for n in 0 to 3 loop
                                                                 
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 
    
                ---------------------------------------------------------------------------
                -- Set-up Page Registers Channel 2
                -- 0x87    r/w    Channel 0 Low byte (23-16) page Register
                -- 0x83    r/w    Channel 1 Low byte (23-16) page Register
                -- 0x81    r/w    Channel 2 Low byte (23-16) page Register
                -- 0x82    r/w    Channel 3 Low byte (23-16) page Register                              
                ---------------------------------------------------------------------------                                  
                outport(PAGE2_REGISTER_C,"----0001");                   -- Program Page Channel 2
                
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                ---------------------------------------------------------------------------                      
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 
                                    
                if n=0 OR n=1 then 
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS LSB
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS MSB
                else
                    outport(BASE_ADDRESS2_C,X"04");                     -- Ch2 Base and Current ADDRESS LSB
                    outport(BASE_ADDRESS2_C,X"00");                     -- Ch2 Base and Current ADDRESS MSB
                end if;
                                        
                outport(BASE_COUNT2_C,X"04");                           -- Ch2 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT2_C,X"00");                           -- Ch2 Base and Current COUNT MSB
                testcount<=5;
    
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Demand Transfer 
                -- Write transfer means WRITE to memory read from IO
                -- Read  transfer means READ from memory write to IO
                ---------------------------------------------------------------------------
                if (n=0) then           
                    outport(MODE_REGISTER_C,"00001010");                -- CH2 Demand, Addr++, READ
                elsif (n=1) then            
                    outport(MODE_REGISTER_C,"00011010");                -- CH2 Demand, AutoInit, Addr++, READ
                elsif (n=2) then            
                    outport(MODE_REGISTER_C,"00101010");                -- CH2 Demand, Addr--, READ
                else                
                    outport(MODE_REGISTER_C,"00111010");                -- CH2 Demand, AutoInit, Addr--, READ
                end if;
    
                ---------------------------------------------------------------------------
                -- Issue command
                ---------------------------------------------------------------------------
                if (n=0) then           
                    outport(COMMAND_REGISTER_C,"00000000");             -- Normal Write
                elsif (n=1) then            
                    outport(COMMAND_REGISTER_C,"00000000");             -- Normal Write
                elsif (n=2) then                            
                    outport(COMMAND_REGISTER_C,"00100000");             -- Extended Write
                else            
                    outport(COMMAND_REGISTER_C,"00001000");             -- Compressed Timing
                end if;
                    
                ---------------------------------------------------------------------------
                -- Unmask Channel 2 only
                ---------------------------------------------------------------------------                         
                outport(MASK_REGISTER_C,"00001011");                    -- Enable CH2 
    
    
                write(L,string'(" ----------- HTL8237 status before memory to IO transfer -------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
            
                ---------------------------------------------------------------------------
                -- Enable TestIO controller
                ---------------------------------------------------------------------------             
                testenable <= '1';                                      -- Enable DMA Request
                testmode   <= "00011";                                  -- Demand transfer
                                
                if (n=0) then
                    write(L,string'(" Start DMA Test 0 Addr++, 5 bytes, address 10000-10004"));
                elsif (n=1) then
                    write(L,string'(" Start DMA Test 1 Addr++, 5 bytes, address 10000-10004, AutoInit"));
                elsif (n=2) then
                    write(L,string'(" Start DMA Test 2 Addr--, 5 bytes, address 10004-10000, Extended write"));
                else 
                    write(L,string'(" Start DMA Test 3 Addr--, 5 bytes, address 10004-10000, Compressed timing, Autoinit"));
                end if;
                writeline(output,L);
   
                --=========================================================================
                -- Start Demand DMA Transfer
                --=========================================================================
                wait until rising_edge(hrq);                            -- 8237 request the bus
                wait until falling_edge(clk);
                wait until falling_edge(clk);
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda <= '1';                                            -- CPU Releases the bus
                abus     <= (others => 'H');            
                iow      <= 'H';            
                ior      <= 'H';            
                MEMW     <= 'H';            
                MEMR     <= 'H';
                                            
                wait until falling_edge(hrq);                           -- Wait for 8237 to remove DMA request
                wait until falling_edge(clk);
                hlda <= '0';                                            -- CPU takes back the bus
                abus     <= (others => '1');            
                iow      <= '1';            
                ior      <= '1';            
                MEMW     <= '1';            
                MEMR     <= '1';    
                write(L,string'("   CPU has access to the bus"));
                writeline(output,L); 

                write(L,string'(" ----------- 82C37 status during memory to IO transfer -------------------- "));   
                writeline(output,L);
                disp_status;                        

                --wait until rising_edge(hrq);                          -- 8237 request the bus
                assert (hrq='1') report "Expected HRQ to be re-asserted during stalled demand mode" severity failure;
                wait until falling_edge(clk);
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda <= '1';                                            -- CPU Releases the bus
                abus     <= (others => 'H');            
                iow      <= 'H';            
                ior      <= 'H';            
                MEMW     <= 'H';            
                MEMR     <= 'H';
                                            
                wait until falling_edge(hrq);                           -- Wait for 8237 to remove DMA request
                wait until falling_edge(clk);
                hlda <= '0';                                            -- CPU takes back the bus
                abus     <= (others => '1');            
                iow      <= '1';            
                ior      <= '1';            
                MEMW     <= '1';            
                MEMR     <= '1';    
                write(L,string'("   CPU has access to the bus"));
                writeline(output,L);    
    
                testenable <= '0';                                      -- end of test
    
                write(L,string'(" ----------- 82C37 status after memory to IO transfer ---------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All

                write(L,string'(""));                                   -- Newline
                writeline(output,L);
                
                wait for 100 ns;
            end loop;
            
            
            
            --=========================================================================
            -- Priority Test
            -- Fixed priority, DREQ0 has the highest priority and DREQ3 has the lowest 
            -- priority. 
            -- Rotating mode, DREQ0 has the highest priority and DREQ3 the lowest, but 
            -- the system rotates through DREQ0, DREQ1, DREQ2, and DREQ3 in that order. 
            --
            --  Test  Action
            --   0   Fixed Priority 
            --   1   Rotate Priority
            --=========================================================================
            write(L,string'(" ======================= Priority Test =============================== "));   
            writeline(output,L);

            for n in 0 to 1 loop
           
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 
                 
                 
                outport(PAGE0_REGISTER_C,"----0001");                   -- Program Page Channel 0
                outport(PAGE1_REGISTER_C,"----0001");                   -- Program Page Channel 1
                outport(PAGE2_REGISTER_C,"----0001");                   -- Program Page Channel 2
                outport(PAGE3_REGISTER_C,"----0001");                   -- Program Page Channel 3
                 
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                ---------------------------------------------------------------------------
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 
                
                outport(BASE_ADDRESS0_C,X"02");                         -- Ch0 Base and Current ADDRESS LSB
                outport(BASE_ADDRESS0_C,X"00");                         -- Ch0 Base and Current ADDRESS MSB
                outport(BASE_ADDRESS1_C,X"04");                         -- Ch1 Base and Current ADDRESS LSB
                outport(BASE_ADDRESS1_C,X"00");                         -- Ch1 Base and Current ADDRESS MSB
                outport(BASE_ADDRESS2_C,X"08");                         -- Ch2 Base and Current ADDRESS LSB
                outport(BASE_ADDRESS2_C,X"00");                         -- Ch2 Base and Current ADDRESS MSB
                outport(BASE_ADDRESS3_C,X"0A");                         -- Ch3 Base and Current ADDRESS LSB
                outport(BASE_ADDRESS3_C,X"00");                         -- Ch3 Base and Current ADDRESS MSB
                    
                outport(BASE_COUNT0_C,X"04");                           -- Ch0 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT0_C,X"00");                           -- Ch0 Base and Current COUNT MSB
                outport(BASE_COUNT1_C,X"04");                           -- Ch1 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT1_C,X"00");                           -- Ch1 Base and Current COUNT MSB
                outport(BASE_COUNT2_C,X"04");                           -- Ch2 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT2_C,X"00");                           -- Ch2 Base and Current COUNT MSB
                outport(BASE_COUNT3_C,X"04");                           -- Ch3 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT3_C,X"00");                           -- Ch3 Base and Current COUNT MSB
                                
                testcount<=5;
         
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Single Transfer 
                -- Write transfer means WRITE to memory read from IO
                -- Read  transfer means READ from memory write to IO
                ---------------------------------------------------------------------------
                outport(MODE_REGISTER_C,"01001000");                    -- All channels single, Addr++, READ
                outport(MODE_REGISTER_C,"01001001");
                outport(MODE_REGISTER_C,"01001010");
                outport(MODE_REGISTER_C,"01001011");
         
                ---------------------------------------------------------------------------
                -- Issue command
                ---------------------------------------------------------------------------
                if (n=1) then
                     outport(COMMAND_REGISTER_C,"00010000");            -- Rotate Priority              
                else
                     outport(COMMAND_REGISTER_C,"00000000");            -- Fixed Priority
                end if;
               
     
                testenable <= '0';                                      -- Keep IO perhiperal disabled for this test
                testmode   <= "00100";                                  -- Indicate Priority test
                
                ---------------------------------------------------------------------------
                -- Unmask Channel 
                ---------------------------------------------------------------------------
                outport(MASK_REGISTER_C,"00000000");                    -- Enable all channels 
         
                write(L,string'(" ----------- 82C37 status before Priority test -------------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
            
     
                --=========================================================================
                -- Start DMA Transfer
                --=========================================================================  
                if (n=0) then
                    write(L,string'(" Start Fixed Priority DMA Test 0 Addr++, 5 bytes, address 10000-10004"));
                else 
                    write(L,string'(" Start Rotate Priority DMA Test 1 Addr--, 5 bytes, address 10000-10004"));
                end if;
                writeline(output,L);
                    
                dreq<=(others => '1');                                  -- All channels are requesting bus access
                
                wait until rising_edge(hrq);    
                wait until falling_edge(clk);   
                wait until falling_edge(clk);   
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda     <= '1';                                        -- Release the bus
                abus     <= (others => 'H');    
                iow      <= 'H';    
                ior      <= 'H';    
                MEMW     <= 'H';    
                MEMR     <= 'H';    
            
                for j in 0 to 3 loop
                    wait until rising_edge(eop_s);                      -- Wait for 4 transfer completes
                end loop;
                
                dreq<=(others => 'L');                                  -- No requests
                
                wait until falling_edge(hrq);   
                wait until falling_edge(clk);   
                wait for 10 ns;                                         
                hlda     <= '0';                                
                abus     <= (others => '1');
                iow      <= '1';
                ior      <= '1';
                MEMW     <= '1';
                MEMR     <= '1';
                wait for 300 ns;            
     
                write(L,string'(" ----------- 82C37 status after Priority test ----------------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
                            
                write(L,string'(""));                                   -- Newline
                writeline(output,L);
     
                wait for 200 ns;
            end loop;


            --=========================================================================
            -- Memory to Memory Transfer
            --
            -- Transfer 4 bytes from 0000-0100 to 8000-0100
            -- 
            --  Test  Action
            --    0   Address 10001 to 80000, Normal Write, CH0++, CH1++
            --    1   Address 10007 to 8001E, AutoInit, CH0--, CH1--
            --    2   Address 1000A to 80007, Extended write, CH0--, CH1++
            --    3   Address 10005 to 80000, Hold CH0, CH1++, fill with 20
            --    4   Address 10000 to 8001F, Hold CH0, CH1--, fill with 48
            --=========================================================================
            write(L,string'(" ======================== Memory to Memory Test ============================ "));   
            writeline(output,L);

            dump_memory(X"10000",X"10020");
            
            for n in 0 to 4 loop
            
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 


                ---------------------------------------------------------------------------
                -- Set-up Page Registers
                -- 0x87    r/w    Channel 0 Low byte (23-16) page Register
                -- 0x83    r/w    Channel 1 Low byte (23-16) page Register
                -- 0x81    r/w    Channel 2 Low byte (23-16) page Register
                -- 0x82    r/w    Channel 3 Low byte (23-16) page Register                              
                ---------------------------------------------------------------------------
                outport(PAGE0_REGISTER_C,"----0001");                   -- 1xxxx, Program Page Channel 0
                outport(PAGE1_REGISTER_C,"----1000");                   -- 8xxxx, Program Page Channel 1
                
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                -- Note CH0 count is not set unless autoinit is required.
                -- CH0=source address
                ---------------------------------------------------------------------------
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 

                -- CH0=Source Address
                if (n=0) then 
                    outport(BASE_ADDRESS0_C,X"01");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB                    
                elsif (n=1) then
                    outport(BASE_ADDRESS0_C,X"07");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB            
                elsif (n=2) then
                    outport(BASE_ADDRESS0_C,X"0A");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB
                elsif (n=3) then
                    outport(BASE_ADDRESS0_C,X"05");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB    
                else
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB    
                    
                end if;                                                      
                outport(BASE_COUNT0_C,X"00");                           -- Ch0 Base and Current COUNT ** IGNORED ** LSB
                outport(BASE_COUNT0_C,X"00");                           -- Ch0 Base and Current COUNT ** IGNORED ** MSB
            
                -- CH1=Destination Address
                if (n=0) then 
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB                    
                elsif (n=1) then                                             
                    outport(BASE_ADDRESS1_C,X"1E");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB            
                elsif (n=2) then                                             
                    outport(BASE_ADDRESS1_C,X"07");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB
                elsif (n=3) then                                                        
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB
                else                                                        
                    outport(BASE_ADDRESS1_C,X"1F");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB                    
                end if; 
                
                outport(BASE_COUNT1_C,X"04");                           -- Ch1 Base and Current COUNT, LSB
                outport(BASE_COUNT1_C,X"00");                           -- Ch1 Base and Current COUNT, MSB

            
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Block Transfer 
                -- Ch0=Read, CH1=Write
                ---------------------------------------------------------------------------     
                if (n=0) then           
                    outport(MODE_REGISTER_C,"10001000");                -- CH0 Block, Addr++, READ
                    outport(MODE_REGISTER_C,"10000101");                -- CH1 Block, Addr++, WRITE
                elsif (n=1) then                                                
                    outport(MODE_REGISTER_C,"10111000");                -- CH0 Block, Addr--, READ
                    outport(MODE_REGISTER_C,"10110101");                -- CH1 Block, Addr--, WRITE
                elsif (n=2 or n=3) then                                                 
                    outport(MODE_REGISTER_C,"10101000");                -- CH0 Block, Addr--, READ
                    outport(MODE_REGISTER_C,"10000101");                -- CH1 Block, Addr++, WRITE
                elsif (n=4) then                                                            
                    outport(MODE_REGISTER_C,"10001000");                -- CH0 Block, Addr++, READ
                    outport(MODE_REGISTER_C,"10100101");                -- CH1 Block, Addr--, WRITE
                end if;

                ---------------------------------------------------------------------------
                -- Issue mem-2-mem command
                ---------------------------------------------------------------------------
                if (n=0) then           
                    outport(COMMAND_REGISTER_C,"00000001");             -- mem2mem enabled
                elsif (n=1) then            
                    outport(COMMAND_REGISTER_C,"00000001");             -- mem2mem enabled
                elsif (n=2) then            
                    outport(COMMAND_REGISTER_C,"00100001");             -- Extended Write, mem2mem enabled
                else            
                    outport(COMMAND_REGISTER_C,"00000011");             -- CH0 Hold, mem2mem enabled
                end if;
             

                testmode   <= "10000";                                  -- Indicate memory test
             
                ---------------------------------------------------------------------------
                -- Unmask Channel 0 only!
                ---------------------------------------------------------------------------
                outport(MASK_REGISTER_C,"00001110");                    -- Enable CH0 
                
                -- write(L,string'(" ----------- 82C37 status before Memory transfer --------------------------- "));   
                -- writeline(output,L);
                -- disp_status;                                         -- Display All
                
                -- dump_memory(X"80000",X"80020");
                        
                ---------------------------------------------------------------------------
                -- Issue Software DREQ command
                ---------------------------------------------------------------------------
                outport(REQUEST_REGISTER_C,"00000100");                 -- Set bit CH0 

                if (n=0) then
                    write(L,string'(" Test 0 Address 10001 to 80000, Normal Write, CH0++, CH1++"));
                elsif (n=1) then
                    write(L,string'(" Test 1 Address 10007 to 8001E, AutoInit, CH0--, CH1--"));
                elsif (n=2) then
                    write(L,string'(" Test 2 Address 1000A to 80007, Extended write, CH0--, CH1++"));
                elsif (n=3) then 
                    write(L,string'(" Test 3 Address 10005 to 80000, Hold CH0, CH1++, fill with 20"));
                else 
                    write(L,string'(" Test 4 Address 10000 to 8001F, Hold CH0, CH1--, fill with 48"));
                end if;
                writeline(output,L);

                
                
                --=========================================================================
                -- Start DMA Transfer
                -- HRQ will be asserted
                --=========================================================================
                wait until rising_edge(hrq);
                wait until falling_edge(clk);
                wait until falling_edge(clk);
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda <= '1';                                            -- Release the bus
                abus     <= (others => 'H');            
                iow      <= 'H';            
                ior      <= 'H';            
                MEMW     <= 'H';            
                MEMR     <= 'H';            
            
                wait until falling_edge(hrq);           
                wait until falling_edge(clk);           
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda     <= '0';                                
                abus     <= (others => '1');
                iow      <= '1';
                ior      <= '1';
                MEMW     <= '1';
                MEMR     <= '1';

                write(L,string'(" ----------- 82C37 status after Memory transfer ---------------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
            
                dump_memory(X"80000",X"80020");
                
                write(L,string'(""));                                   -- Newline
                writeline(output,L);
         
                wait for 200 ns;
            end loop;       
            
            --=========================================================================
            -- Ready test using Memory Read to IO Write Block Transfer
            -- Note READY is sampled at the falling edge between S3 and S4
            --
            --  Test  Action, read with waitstates
            --    0   Addr++, 2 bytes, address 10000-10004, First memory Read requires 2 WS, READ 
            --    1   Addr++, 2 bytes, address 10000-10004, First memory Write requires 2 WS, WRITE
            --    2   Addr++, 2 bytes, address 10000-10004, Extended memory write, 2 WS, WRITE
            --    3   Addr++, 2 bytes, address 10000-10004, IO write requires 1 WS, READ  
            --    4   Addr++, 2 bytes, address 10000-10004, IO Read requires 1 WS, WRITE
            --=========================================================================
            write(L,string'(" ======================= READY input Test ============================ "));   
            writeline(output,L);
                       
            for n in 0 to 4 loop
                                                                 
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 
    
                ---------------------------------------------------------------------------
                -- Set-up Page Registers Channel 2                          
                ---------------------------------------------------------------------------                                  
                outport(PAGE2_REGISTER_C,"----0001");                   -- Program Page Channel 2
                
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                ---------------------------------------------------------------------------                      
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 
                                    
                outport(BASE_ADDRESS2_C,X"00");                         -- Ch2 Base and Current ADDRESS LSB
                outport(BASE_ADDRESS2_C,X"00");                         -- Ch2 Base and Current ADDRESS MSB
    
                                        
                outport(BASE_COUNT2_C,X"01");                           -- Ch2 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT2_C,X"00");                           -- Ch2 Base and Current COUNT MSB
                testcount<=5;
    
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Block Transfer 
                -- Write transfer means WRITE to memory read from IO
                -- Read  transfer means READ from memory write to IO
                ---------------------------------------------------------------------------
                if (n=0 or n=3) then            
                    outport(MODE_REGISTER_C,"10001010");                -- CH2 Block, Addr++, READ
                else            
                    outport(MODE_REGISTER_C,"10000110");                -- CH2 Block, Addr++, WRITE
                end if;
    
                ---------------------------------------------------------------------------
                -- Issue command
                ---------------------------------------------------------------------------
                if (n=2) then                           
                    outport(COMMAND_REGISTER_C,"00100000");             -- Extended Write
                else 
                    outport(COMMAND_REGISTER_C,"00000000");             -- Normal Write
                end if;
                    
                ---------------------------------------------------------------------------
                -- Unmask Channel 2 only
                ---------------------------------------------------------------------------                         
                outport(MASK_REGISTER_C,"00001011");                    -- Enable CH2 
    
    
                -- write(L,string'(" ----------- HTL8237 status before memory to IO transfer -------------------- "));   
                -- writeline(output,L);
                -- disp_status;                                         -- Display All
            
                ---------------------------------------------------------------------------
                -- Enable TestIO controller
                ---------------------------------------------------------------------------             
                testenable <= '1';                                      -- Enable DMA Request
                
                                
                if (n=0) then
                    write(L,string'(" Start DMA Test 0 Addr++, 2 bytes, address 10000-10004, assert READY for memory read"));
                    testmode   <= "00110";                              -- Read Block transfer to test Ready
                elsif (n=1) then
                    write(L,string'(" Start DMA Test 1 Addr++, 2 bytes, address 10000-10004, assert READY for memory write"));
                    testmode   <= "00111";                              -- Write Block transfer to test Ready
                elsif (n=2) then
                    write(L,string'(" Start DMA Test 2 Addr++, 2 bytes, address 10000-10004, Extended Write, assert READY for memory write"));
                    testmode   <= "00111";                              -- Extended Write Block transfer to test Ready
                elsif (n=3) then
                    write(L,string'(" Start DMA Test 3 Addr++, 2 bytes, address 10000-10004, assert READY for IO write"));
                    testmode   <= "01000";                              -- Extended Write Block transfer to test Ready
                else    
                    write(L,string'(" Start DMA Test 4 Addr++, 2 bytes, address 10000-10004, assert READY for IO read"));
                    testmode   <= "01001";              
                end if;
                writeline(output,L);
   
                --=========================================================================
                -- Start Block DMA Transfer
                --=========================================================================
                wait until rising_edge(hrq);                            -- 8237 request the bus
                wait until falling_edge(clk);
                wait until falling_edge(clk);
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda <= '1';                                            -- CPU Releases the bus
                abus     <= (others => 'H');            
                iow      <= 'H';            
                ior      <= 'H';            
                MEMW     <= 'H';            
                MEMR     <= 'H';
                                            
                wait until falling_edge(hrq);                           -- Wait for 8237 to remove DMA request
                wait until falling_edge(clk);
                hlda <= '0';                                            -- CPU takes back the bus
                abus     <= (others => '1');            
                iow      <= '1';            
                ior      <= '1';            
                MEMW     <= '1';            
                MEMR     <= '1';    
                write(L,string'("   CPU has access to the bus"));
                writeline(output,L);                            

                testenable <= '0';                                      -- end of test
    
                -- write(L,string'(" ----------- 82C37 status after memory to IO transfer ---------------------- "));   
                -- writeline(output,L);
                -- disp_status;                                         -- Display All

                write(L,string'(""));                                   -- Newline
                writeline(output,L);
                
                wait for 100 ns;
            end loop;
                        
            --=========================================================================
            -- EOP test memory to/from IO
            -- When an EOP pulse occurs, whether internally or externally generated, the 
            -- 82C37A will terminate the service, and if autoinitialize is enabled, the 
            -- base registers will be written to the current registers of that channel. 
            -- The mask bit and TC bit in the status word will be set for the currently 
            -- active channel by EOP unless the channel is programmed for autoinitialize. 
            -- In that case, the mask bit remains clear.
            --
            --  Test  Action, read with waitstates
            --    0   Addr++, 11 bytes, address 10000-10040, Issue EOP after byte 2, READ 
            --    1   Addr++, 11 bytes, address 10000-10040, Issue EOP after byte 2, autoinit, READ
            --    2   Addr++, 11 bytes, address 10000-10040, Issue EOP to Master (ignored) after byte 2, READ
            --=========================================================================
            write(L,string'(" ======================= EOP input Test ================================ "));   
            writeline(output,L);
                       
            for n in 0 to 2 loop
                                                                 
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 
    
                ---------------------------------------------------------------------------
                -- Set-up Page Registers Channel 2                          
                ---------------------------------------------------------------------------                                  
                outport(PAGE2_REGISTER_C,"----0001");                   -- Program Page Channel 2
                
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                ---------------------------------------------------------------------------                      
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 
                                    
                outport(BASE_ADDRESS2_C,X"00");                         -- Ch2 Base and Current ADDRESS LSB
                outport(BASE_ADDRESS2_C,X"00");                         -- Ch2 Base and Current ADDRESS MSB
                                
                outport(BASE_COUNT2_C,X"0A");                           -- Ch2 Base and Current COUNT LSB (Length-1)
                outport(BASE_COUNT2_C,X"00");                           -- Ch2 Base and Current COUNT MSB
                testcount<=5;
    
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Block Transfer 
                -- Write transfer means WRITE to memory read from IO
                -- Read  transfer means READ from memory write to IO
                ---------------------------------------------------------------------------
                if (n=0) then           
                    outport(MODE_REGISTER_C,"10001010");                -- CH2 Block, Addr++, READ
                elsif (n=1) then
                    outport(MODE_REGISTER_C,"10011010");                -- CH2 Block, Addr++, autoinit, READ
                else            
                    outport(MODE_REGISTER_C,"10001010");                -- CH2 Block, Addr++, READ
                end if;
    
                ---------------------------------------------------------------------------
                -- Issue command
                ---------------------------------------------------------------------------
                outport(COMMAND_REGISTER_C,"00000000");                 -- Normal Write
                   
                ---------------------------------------------------------------------------
                -- Unmask Channel 2 only
                ---------------------------------------------------------------------------                         
                outport(MASK_REGISTER_C,"00001011");                    -- Enable CH2 
       
                write(L,string'(" ----------- HTL8237 status before memory to IO transfer -------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
            
                                
                if (n=0) then
                    write(L,string'(" Start DMA Test 0 Addr++, 11 bytes, address 10000-10040, Issue EOP after byte 2, READ"));
                    testenable <= '1';                                  -- Enable DMA Request
                    testmode   <= "01010";                              -- Read Block transfer to test EOP
                elsif (n=1) then
                    write(L,string'(" Start DMA Test 1 Addr++, 11 bytes, address 10000-10040, Issue EOP after byte 2, autoinit, READ"));
                    testenable <= '1';                                  -- Enable DMA Request
                    testmode   <= "01010";                              -- Write Block transfer to test EOP
                elsif (n=2) then
                    write(L,string'(" Start DMA Test 2 Addr++, 11 bytes, address 10000-10040, Issue Spurious EOP to Master after byte 2, READ"));
                    testenable <= '1';                                  -- Enable DMA Request   
                    testmode   <= "01011";                              -- Extended Write Block transfer            
                end if;
                writeline(output,L);
   
                --=========================================================================
                -- Start Block DMA Transfer
                --=========================================================================
                wait until rising_edge(hrq);                            -- 8237 request the bus
                wait until falling_edge(clk);
                wait until falling_edge(clk);
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda <= '1';                                            -- CPU Releases the bus
                abus     <= (others => 'H');            
                iow      <= 'H';            
                ior      <= 'H';            
                MEMW     <= 'H';            
                MEMR     <= 'H';
                                            
                wait until falling_edge(hrq);                           -- Wait for 8237 to remove DMA request
                wait until falling_edge(clk);
                hlda <= '0';                                            -- CPU takes back the bus
                abus     <= (others => '1');            
                iow      <= '1';            
                ior      <= '1';            
                MEMW     <= '1';            
                MEMR     <= '1';    
                write(L,string'("   CPU has access to the bus"));
                writeline(output,L);                            

                testenable <= '0';                                      -- end of test
    
                write(L,string'(" ----------- 82C37 status after memory to IO transfer ---------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All

                write(L,string'(""));                                   -- Newline
                writeline(output,L);
                
                wait for 100 ns;
            end loop;
            
            
            --=========================================================================
            -- Test EOP Memory to Memory Transfer
            --
            -- Transfer 4 bytes from 0000-0100 to 8000-0100
            -- 
            --  Test  Action
            --    0   Address 10001 to 80000, Normal Write, CH0++, CH1++
            --    1   Address 10007 to 8001E, AutoInit, CH0--, CH1--
            --    2   Address 1000A to 80007, Extended write, CH0--, CH1++
            --    3   Address 10003 to 8002F, Compressed Timing,Autoinit CH1++, CH1--
            --    4   Address 10005 to 80000, Hold CH0, CH1++, fill with 20
            --    5   Address 10000 to 8001F, Hold CH0, CH1--, fill with 48
            --=========================================================================
            write(L,string'(" ======================== EOP Memory to Memory Test ======================== "));   
            writeline(output,L);

            dump_memory(X"10000",X"10020");
            
            for n in 0 to 6 loop
            
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 

                ---------------------------------------------------------------------------
                -- Set-up Page Registers
                -- 0x87    r/w    Channel 0 Low byte (23-16) page Register
                -- 0x83    r/w    Channel 1 Low byte (23-16) page Register
                -- 0x81    r/w    Channel 2 Low byte (23-16) page Register
                -- 0x82    r/w    Channel 3 Low byte (23-16) page Register                              
                ---------------------------------------------------------------------------
                outport(PAGE0_REGISTER_C,"----0001");                   -- 1xxxx, Program Page Channel 0
                outport(PAGE1_REGISTER_C,"----1000");                   -- 8xxxx, Program Page Channel 1
                
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                -- Note CH0 count is not set unless autoinit is required.
                -- CH0=source address
                ---------------------------------------------------------------------------
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 

                if (n=0) then 
                    outport(BASE_ADDRESS0_C,X"01");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB                    
                elsif (n=1) then
                    outport(BASE_ADDRESS0_C,X"07");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB            
                elsif (n=2) then
                    outport(BASE_ADDRESS0_C,X"0A");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB
                elsif (n=3) then
                    outport(BASE_ADDRESS0_C,X"03");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB
                elsif (n=4) then
                    outport(BASE_ADDRESS0_C,X"05");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB    
                else
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, LSB
                    outport(BASE_ADDRESS0_C,X"00");                     -- Ch0 Base and Current Address, MSB    
                    
                end if;                                                      
                outport(BASE_COUNT0_C,X"00");                           -- Ch0 Base and Current COUNT ** IGNORED ** LSB
                outport(BASE_COUNT0_C,X"00");                           -- Ch0 Base and Current COUNT ** IGNORED ** MSB
            
                -- CH1=Destination address
                if (n=0) then 
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB                    
                elsif (n=1) then                                             
                    outport(BASE_ADDRESS1_C,X"1E");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB            
                elsif (n=2) then                                             
                    outport(BASE_ADDRESS1_C,X"07");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB
                elsif (n=3) then                                                        
                    outport(BASE_ADDRESS1_C,X"2F");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB
                elsif (n=4) then                                                        
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB
                else                                                        
                    outport(BASE_ADDRESS1_C,X"1F");                     -- Ch1 Base and Current Address, LSB
                    outport(BASE_ADDRESS1_C,X"00");                     -- Ch1 Base and Current Address, MSB                    
                end if; 
                
                outport(BASE_COUNT1_C,X"04");                           -- Ch1 Base and Current COUNT, LSB
                outport(BASE_COUNT1_C,X"00");                           -- Ch1 Base and Current COUNT, MSB

            
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Block Transfer 
                -- Ch0=Read, CH1=Write
                ---------------------------------------------------------------------------     
                if (n=0) then           
                    outport(MODE_REGISTER_C,"10001000");                -- CH0 Block, Addr++, READ
                    outport(MODE_REGISTER_C,"10000101");                -- CH1 Block, Addr++, WRITE
                elsif (n=1) then                                                
                    outport(MODE_REGISTER_C,"10111000");                -- CH0 Block, Addr--, READ
                    outport(MODE_REGISTER_C,"10110101");                -- CH1 Block, Addr--, WRITE
                elsif (n=2 or n=4) then                                                 
                    outport(MODE_REGISTER_C,"10101000");                -- CH0 Block, Addr--, READ
                    outport(MODE_REGISTER_C,"10000101");                -- CH1 Block, Addr++, WRITE
                elsif (n=3 or n=5) then                                                             
                    outport(MODE_REGISTER_C,"10001000");                -- CH0 Block, Addr++, READ
                    outport(MODE_REGISTER_C,"10100101");                -- CH1 Block, Addr--, WRITE
                end if;

                ---------------------------------------------------------------------------
                -- Issue mem-2-mem command
                ---------------------------------------------------------------------------
                if (n=0) then           
                    outport(COMMAND_REGISTER_C,"00000001");             -- mem2mem enabled
                elsif (n=1) then            
                    outport(COMMAND_REGISTER_C,"00000001");             -- mem2mem enabled
                elsif (n=2) then            
                    outport(COMMAND_REGISTER_C,"00100001");             -- Extended Write, mem2mem enabled
                elsif (n=3) then            
                    outport(COMMAND_REGISTER_C,"00001001");             -- Compressed, mem2mem enabled
                else            
                    outport(COMMAND_REGISTER_C,"00000011");             -- CH0 Hold, mem2mem enabled
                end if;
             
                testmode   <= "01011";                                  -- EOP mem2mem 
             
                ---------------------------------------------------------------------------
                -- Unmask Channel 0 only!
                ---------------------------------------------------------------------------
                outport(MASK_REGISTER_C,"00001110");                    -- Enable CH0 
                            
                write(L,string'(" ----------- HTL8237 status before Memory to Memory transfer ----------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
                            
                ---------------------------------------------------------------------------
                -- Issue Software DREQ command
                ---------------------------------------------------------------------------
                outport(REQUEST_REGISTER_C,"00000100");                 -- Set bit CH0 

                if (n=0) then
                    write(L,string'(" Test 0 Address 10001 to 80000, Normal Write, CH0++, CH1++"));
                elsif (n=1) then
                    write(L,string'(" Test 1 Address 10007 to 8001E, AutoInit, CH0--, CH1--"));
                elsif (n=2) then
                    write(L,string'(" Test 2 Address 1000A to 80007, Extended write, CH0--, CH1++"));
                elsif (n=3) then 
                    write(L,string'(" Test 3 Address 10003 to 8002F, Compressed,Autoinit CH1++, CH1--"));
                elsif (n=4) then 
                    write(L,string'(" Test 4 Address 10005 to 80000, Hold CH0, CH1++, fill with 20"));
                else 
                    write(L,string'(" Test 5 Address 10000 to 8001F, Hold CH0, CH1--, fill with 48"));
                end if;
                writeline(output,L);

                
                
                --=========================================================================
                -- Start DMA Transfer
                -- HRQ will be asserted
                --=========================================================================
                wait until rising_edge(hrq);
                wait until falling_edge(clk);
                wait until falling_edge(clk);
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda <= '1';                                            -- Release the bus
                abus     <= (others => 'H');            
                iow      <= 'H';            
                ior      <= 'H';            
                MEMW     <= 'H';            
                MEMR     <= 'H';    

                wait until rising_edge(MEMW);                           -- End of 1st transfer
                    
                if (n=0) then                                           -- assert EOP during S11-S12
                    eop <= '0';                                         -- Wait until S24
                else                                                    -- Assert EOP during S21-S22
                    wait until rising_edge(MEMR);                       
                    eop <= '0';                                         -- terminate transfer
                end if;
                write(L,string'("External EOP asserted!"));
                writeline(output,L);
                wait until falling_edge(clk);
                wait for 5 ns;
                eop <= 'H'; 

                wait until falling_edge(hrq);           
                wait until falling_edge(clk);           
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda     <= '0';                                
                abus     <= (others => '1');
                iow      <= '1';
                ior      <= '1';
                MEMW     <= '1';
                MEMR     <= '1';

                write(L,string'(" ----------- 82C37 status after Memory to Memory transfer ---------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
            
                dump_memory(X"80000",X"80020");
                
                write(L,string'(""));                                   -- Newline
                writeline(output,L);
         
                wait for 200 ns;
            end loop;
                        
                        
            --=========================================================================
            -- Test Memory to Memory Verify/Ready Transfer
            --
            -- Transfer 4 bytes from 0000-0100 to 8000-0100
            -- 
            --  Test  Action
            --    0   Address 10001 to 80000, Verify, CH0++, CH1++
            --    1   Address 10001 to 80000, Verify with Ready, CH0++, CH1++
            --=========================================================================
            write(L,string'(" ======================== Memory to Memory Verify/Ready Test =================== "));   
            writeline(output,L);

            dump_memory(X"80000",X"80020");
            
            for n in 0 to 1 loop
            
                outport(MASK_REGISTER_C,"----1111");                    -- Disable all channels 

                ---------------------------------------------------------------------------
                -- Set-up Page Registers
                -- 0x87    r/w    Channel 0 Low byte (23-16) page Register
                -- 0x83    r/w    Channel 1 Low byte (23-16) page Register
                -- 0x81    r/w    Channel 2 Low byte (23-16) page Register
                -- 0x82    r/w    Channel 3 Low byte (23-16) page Register                              
                ---------------------------------------------------------------------------
                outport(PAGE0_REGISTER_C,"----0001");                   -- 1xxxx, Program Page Channel 0
                outport(PAGE1_REGISTER_C,"----1000");                   -- 8xxxx, Program Page Channel 1
                
                ---------------------------------------------------------------------------
                -- Clear first/last FF, then set-up Base and Count registers
                -- Note CH0 count is not set unless autoinit is required.
                -- CH0=source address
                ---------------------------------------------------------------------------
                outport(FIRST_LAST_FF_C,"--------");                    -- Clear First/Last FF 

                outport(BASE_ADDRESS0_C,X"01");                         -- Ch0 Base and Current Address, LSB
                outport(BASE_ADDRESS0_C,X"00");                         -- Ch0 Base and Current Address, MSB                    
                                                     
                outport(BASE_COUNT0_C,X"55");                           -- Ch0 Base and Current COUNT ** IGNORED ** LSB
                outport(BASE_COUNT0_C,X"55");                           -- Ch0 Base and Current COUNT ** IGNORED ** MSB
            
                -- CH1=Destination address
                outport(BASE_ADDRESS1_C,X"00");                         -- Ch1 Base and Current Address, LSB
                outport(BASE_ADDRESS1_C,X"00");                         -- Ch1 Base and Current Address, MSB                    
                                
                outport(BASE_COUNT1_C,X"01");                           -- Ch1 Base and Current COUNT, LSB
                outport(BASE_COUNT1_C,X"00");                           -- Ch1 Base and Current COUNT, MSB

            
                ---------------------------------------------------------------------------
                -- Program Mode Register, Use Block Transfer 
                -- Ch0=Read, CH1=Write
                ---------------------------------------------------------------------------     
                outport(MODE_REGISTER_C,"10000000");                    -- CH0 Block, Addr++, Verify
                outport(MODE_REGISTER_C,"10000001");                    -- CH1 Block, Addr++, Verify

                ---------------------------------------------------------------------------
                -- Issue mem-2-mem command
                ---------------------------------------------------------------------------
                outport(COMMAND_REGISTER_C,"00000001");                 -- mem2mem enabled
                           
                ---------------------------------------------------------------------------
                -- Unmask Channel 0 only!
                ---------------------------------------------------------------------------
                outport(MASK_REGISTER_C,"00001110");                    -- Enable CH0 
                            
                write(L,string'(" ----------- HTL8237 status before Memory to Memory transfer ----------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
                            
                ---------------------------------------------------------------------------
                -- Issue Software DREQ command
                ---------------------------------------------------------------------------
                outport(REQUEST_REGISTER_C,"00000100");                 -- Set bit CH0 

                if (n=0) then
                    write(L,string'(" Test 0 Address 10001 to 80000, Verify, CH0++, CH1++"));
                    testmode   <= "01100";                              -- Verify Mode
                else 
                    write(L,string'(" Test 0 Address 10001 to 80000, Verify+READY, CH0++, CH1++"));
                    testenable <= '1';                                  -- Enable Ready generation
                    testmode   <= "01101";                              -- Verify Mode +Ready
                end if;
                writeline(output,L);        
                
                --=========================================================================
                -- Start DMA Transfer
                -- HRQ will be asserted
                --=========================================================================
                wait until rising_edge(hrq);
                wait until falling_edge(clk);
                wait until falling_edge(clk);
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda <= '1';                                            -- Release the bus
                abus     <= (others => 'H');            
                iow      <= 'H';            
                ior      <= 'H';            
                MEMW     <= 'H';            
                MEMR     <= 'H';                

                wait until falling_edge(hrq);           
                wait until falling_edge(clk);           
                wait for 10 ns;                                         -- Tclhav 10-160 ns, Regain the bus
                hlda     <= '0';                                
                abus     <= (others => '1');
                iow      <= '1';
                ior      <= '1';
                MEMW     <= '1';
                MEMR     <= '1';

                testenable <= '0';                                      -- end of test
                
                write(L,string'(" ----------- 82C37 status after Memory to Memory transfer ---------------------- "));   
                writeline(output,L);
                disp_status;                                            -- Display All
            
                dump_memory(X"80000",X"80020");
                
                write(L,string'(""));                                   -- Newline
                writeline(output,L);
         
                wait for 200 ns;
            end loop;                       
                        

            assert FALSE report ("------- End of test ------ ") severity failure;
            wait;
    end process;
END ARCHITECTURE behavioral;

