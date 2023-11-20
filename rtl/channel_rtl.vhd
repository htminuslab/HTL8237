-------------------------------------------------------------------------------
--  HTL8237                                                                  --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : I8237                                                     --
-- Module        : Address/Count Registers                                   --
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

ENTITY channel IS
   GENERIC( 
      channel_id : std_logic_vector(1 downto 0) := "00"
   );
   PORT( 
      abusl_in         : IN     std_logic_vector (3 DOWNTO 0);
      dbus_in          : IN     std_logic_vector (7 DOWNTO 0);
      endbuscycle      : IN     std_logic;
      eop_in           : IN     std_logic;                       -- Active high!
      master_clear     : IN     std_logic;
      firstlast_ff     : IN     std_logic;
      wr               : IN     std_logic;
      ch0_address_hold : IN     std_logic;
      current_addr     : OUT    std_logic_vector (15 DOWNTO 0);
      current_count    : OUT    std_logic_vector (15 DOWNTO 0);
      mode_reg         : OUT    std_logic_vector (5 DOWNTO 0);   -- only 7 downto 2, 1-0="11"
      tc               : OUT    std_logic;
      mem_2_mem        : IN     std_logic;
      clk              : IN     std_logic;
      reset            : IN     std_logic;
      borrowcarry      : OUT    std_logic;
      autoinit         : OUT    std_logic;
      count_is_zero    : OUT    std_logic
   );
END channel ;


ARCHITECTURE rtl OF channel IS

signal base_address_reg     : unsigned(15 downto 0);
signal base_count_reg       : unsigned(15 downto 0);
signal current_address_reg  : unsigned(15 downto 0);
signal current_count_reg    : unsigned(15 downto 0);

-- Mode Register bits
signal transfer             : std_logic_vector(1 downto 0);
signal autoinit_s           : std_logic;
signal addrdec              : std_logic;
signal modesel              : std_logic_vector(1 downto 0);

signal count_is_zero_s      : std_logic;
signal tc_s                 : std_logic; 

BEGIN
        
    ---------------------------------------------------------------------------
    -- 6-bits Mode Register
    ---------------------------------------------------------------------------
    process(reset, clk) 
        begin
            if (reset='1') then
                transfer  <= "00";           -- Default to Verify Transfer
                autoinit_s<= '0';            -- Default disable autoinitialise
                addrdec   <= '0';            -- Default to Address Increment
                modesel   <= "00";           -- Default to Demand mode select
            elsif falling_edge(clk) then
                if master_clear='1' then
                    transfer  <= "00";       
                    autoinit_s<= '0';        
                    addrdec   <= '0';        
                    modesel   <= "00";       
                elsif (wr='1' AND abusl_in=WRITE_MODE_REG_C AND dbus_in(1 downto 0)=channel_id) then
                    transfer   <= dbus_in(3 downto 2);
                    autoinit_s <= dbus_in(4);
                    addrdec    <= dbus_in(5); -- 0=INCR, 1=DECR
                    modesel    <= dbus_in(7 downto 6);            
                end if;
          end if;
    end process;
    mode_reg <= modesel & addrdec & autoinit_s & transfer; -- 6 bits only
    autoinit <= autoinit_s;

    ---------------------------------------------------------------------------
    -- Base Address Register
    -- Base Word Register
    -- Note Falling edge!
    ---------------------------------------------------------------------------
    process (reset,clk)
        begin
            if reset='1' then
                base_address_reg    <= (others => '0');
                base_count_reg <= (others => '0');      
            elsif falling_edge(clk) then
                if wr='1' AND abusl_in='0'&channel_id&'0' then
                    if firstlast_ff='0' then
                        base_address_reg(7 downto 0)<= unsigned(dbus_in);
                    else 
                        base_address_reg(15 downto 8)<= unsigned(dbus_in);
                    end if;
                end if;
                if wr='1' AND abusl_in='0'&channel_id&'1' then
                    if firstlast_ff='0' then
                        base_count_reg(7 downto 0)<= unsigned(dbus_in);
                    else 
                        base_count_reg(15 downto 8)<= unsigned(dbus_in);
                    end if;
                end if;
            end if;
    end process;
    

    ---------------------------------------------------------------------------
    -- Current Address Register
    --    * Address can be incremented or decremented
    --
    -- Current Word Register
    --    * Word register is decremented after transfer
    --
    -- During EOP and AutoInit reload current from base register
    -- 
    -- When Word Count decrements to FFFF the TC is asserted.
    --
    -- The actual number of transfers will be one more than the number programmed 
    -- in the Current Word Count register.
    --
    -- Note Falling edge!
    ---------------------------------------------------------------------------
    process (reset,clk)
        begin
            if reset='1' then
                current_address_reg <= (others => '0');
                current_count_reg   <= (others => '0'); 
            elsif falling_edge(clk) then
                --if ((endbuscycle='1' AND tc_s='1') OR eop_in='1') AND autoinit_s='1' then
                if (tc_s='1' OR eop_in='1') AND autoinit_s='1' then
                    
                    current_address_reg <= base_address_reg; -- Auto Init Registers
                    current_count_reg <= base_count_reg;
               
                elsif endbuscycle='1' then

                    current_count_reg <= current_count_reg - 1;
                    
                    -- In memory-to-memory mode, Channel 0 may be programmed to retain 
                    -- the same address for all transfers.
                    -- This allows a single byte to be written to a block of memory.
                    if NOT (ch0_address_hold='1' AND channel_id="00") then
                        if addrdec='1' then
                            current_address_reg<= current_address_reg - 1;
                        else
                            current_address_reg<= current_address_reg + 1;
                        end if;
                    end if;

                elsif wr='1' AND abusl_in='0'&channel_id&'0' then
                    if firstlast_ff='0' then
                        current_address_reg(7 downto 0)<= unsigned(dbus_in);
                    else 
                        current_address_reg(15 downto 8)<= unsigned(dbus_in);
                    end if;

                elsif wr='1' AND abusl_in='0'&channel_id&'1' then
                    if firstlast_ff='0' then
                        current_count_reg(7 downto 0)<= unsigned(dbus_in);
                    else 
                        current_count_reg(15 downto 8)<= unsigned(dbus_in);
                    end if;
                end if;
            end if;
    end process;

    current_addr  <= STD_LOGIC_VECTOR(current_address_reg);
    current_count <= STD_LOGIC_VECTOR(current_count_reg);

    -- Combinational pulse, must be sampled in a clocked process
    count_is_zero_s <= '1' when current_count_reg=X"0000" else '0';
    count_is_zero<=count_is_zero_s;                 -- Change VHDL200x later on
    
    ---------------------------------------------------------------------------
    -- Generate Borrow/Carry signal, if this signal is asserted
    -- then adstb pulse is generated, if not then S11/S1 is skipped
    -- ch0_address_hold only connected to channel 0
    ---------------------------------------------------------------------------
    process(endbuscycle,ch0_address_hold,current_address_reg,addrdec)
        begin
            if endbuscycle='1' AND ch0_address_hold='0' then
                if addrdec='1' then
                    if current_address_reg(7 downto 0)=X"00" then --from 00 to FF
                        borrowcarry<='1';
                    else
                        borrowcarry<='0';   
                    end if;
                else
                    if current_address_reg(7 downto 0)=X"FF" then --from FF to 00
                        borrowcarry<='1';
                    else
                        borrowcarry<='0';   
                    end if;
                end if;
            else
                borrowcarry<='0';   
            end if;
    end process;
    ---------------------------------------------------------------------------
    -- A pulse is generated by the HTL8237 when the terminal count (TC) for any 
    -- channel is reached, combinatorial pulse!
    -- Disabled when in Cascade mode
    -- Asserted during S24/S4.
    ---------------------------------------------------------------------------
    tc_s<= '1' WHEN (endbuscycle='1' AND count_is_zero_s='1') AND mem_2_mem='0' AND modesel/="11" else '0';
    tc  <= tc_s;                                    -- Change for VHDL200x later on

END ARCHITECTURE rtl;
