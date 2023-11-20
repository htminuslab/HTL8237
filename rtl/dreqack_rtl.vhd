-------------------------------------------------------------------------------
--  HTL8237                                                                  --
--                                                                           --
--  https://github.com/htminuslab                                            --
--                                                                           --
-------------------------------------------------------------------------------
-- Project       : I8237                                                     --
-- Module        : DMA Request/Ack logic                                     --
-- Library       :                                                           --
--                                                                           --
-- Version       : 1.0  20/01/2005   Created HT-LAB                          --
--               : 1.1  05/05/2016   Added delayed clr signal for status reg --  
--               : 1.2  30/11/2023   Uploaded to github under MIT license    --                                                       
--                                   checked with Questa/Modelsim 2023.4     --
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.NUMERIC_STD.all;

USE work.pack8237.all;

ENTITY dreqack IS
   PORT( 
      abusl_in         : IN     std_logic_vector (3 DOWNTO 0);
      aen_s            : IN     std_logic;
      autoinit         : IN     std_logic_vector (3 DOWNTO 0);
      clk              : IN     std_logic;
      dack_active_high : IN     std_logic;
      dbus_in          : IN     std_logic_vector (7 DOWNTO 0);
      dreq             : IN     std_logic_vector (3 DOWNTO 0);
      dreq_sense_low   : IN     std_logic;
      endbuscycle      : IN     std_logic;
      endbuscycle_s    : IN     std_logic_vector (3 DOWNTO 0);
      eop_in_s         : IN     std_logic_vector (3 DOWNTO 0);
      hlda             : IN     std_logic;
      hrqn_s           : IN     std_logic;
      master_clear     : IN     std_logic;
      mem_2_mem        : IN     std_logic;
      mem_chan         : IN     std_logic;
      rd               : IN     std_logic;
      reset            : IN     std_logic;
      rotate_priority  : IN     std_logic;
      tc               : IN     std_logic_vector (3 DOWNTO 0);
      wr               : IN     std_logic;
      dack             : OUT    std_logic_vector (3 DOWNTO 0);
      dma_chan         : OUT    std_logic_vector (1 DOWNTO 0);
      dma_req          : OUT    std_logic;
      dma_req_mode0    : OUT    std_logic;
      mask_reg         : OUT    std_logic_vector (3 DOWNTO 0);
      request_reg      : OUT    std_logic_vector (3 DOWNTO 0);
      status_reg       : OUT    std_logic_vector (7 DOWNTO 0);
      eop_latched      : IN     std_logic;
      rdpulse          : IN     std_logic           -- Version 1.3
   );
END dreqack ;

ARCHITECTURE rtl OF dreqack IS

signal rot           : unsigned(1 downto 0);
signal sel           : std_logic_vector(5 downto 0);
signal tcall         : std_logic;

signal dreq_s        : std_logic_vector(3 downto 0);
signal dma_inp_s     : std_logic_vector(3 downto 0);
signal request_reg_s : std_logic_vector(3 downto 0);
signal mask_reg_s    : std_logic_vector (3 DOWNTO 0);

signal dma_req_s     : std_logic;
signal dma_reql_s    : std_logic;
signal dma_chan_s    : std_logic_vector(1 downto 0);
signal dma_chanl_s   : std_logic_vector(1 downto 0);

signal clr_status_reg_s : std_logic;        -- version 1.3

BEGIN
     
    ---------------------------------------------------------------------------
    -- Mask Register
    -- 1=disable DREQ
    -- Commands:    Write single mask bit
    --              Clear mask register
    --              Read All mask bits
    --              Write All mask bits
    --
    -- Each mask bit is set when its associated channel produces an EOP
    -- if the channel is not programmed to Autoinitialize.
    --
    -- DACK init to active low after reset
    -- DREQ init to active high after reset
    --
    ---------------------------------------------------------------------------
    process (reset,clk)
        begin
            if reset='1' then
                mask_reg_s <= (others => '1');
            elsif falling_edge(clk) then
                if master_clear='1' then
                    mask_reg_s <= (others => '1');
                elsif wr='1' AND abusl_in=CLEAR_MASK_REGISTER_C then
                    mask_reg_s <= (others => '0');                  -- Enable All!
                elsif wr='1' and abusl_in=WRITE_ALL_MASK_BITS_C then
                    mask_reg_s <= dbus_in(3 downto 0);
                elsif wr='1' and abusl_in=WRITE_SMASK_BIT_C then    -- Write Single mask bit
                    case dbus_in(1 downto 0) is 
                       when "00"   => mask_reg_s(0)<=dbus_in(2); 
                       when "01"   => mask_reg_s(1)<=dbus_in(2);   
                       when "10"   => mask_reg_s(2)<=dbus_in(2);   
                       when others => mask_reg_s(3)<=dbus_in(2);
                    end case;
                else 
                    if (eop_in_s(0)='1' OR tc(0)='1') then mask_reg_s(0)<= not autoinit(0); end if;
                    if (eop_in_s(1)='1' OR tc(1)='1') then mask_reg_s(1)<= not autoinit(1); end if;
                    if (eop_in_s(2)='1' OR tc(2)='1') then mask_reg_s(2)<= not autoinit(2); end if;
                    if (eop_in_s(3)='1' OR tc(3)='1') then mask_reg_s(3)<= not autoinit(3); end if;
                end if;
            end if;
    end process;
    mask_reg <= mask_reg_s;

    ---------------------------------------------------------------------------
    -- Request Register
    -- 
    -- 1=Request DMA,  cleared by TC EOP or master clear
    --
    -- Each register bit is set or reset separately under software control or is 
    -- cleared upon generation of a TC or external EOP.
    --
    -- A software request for DMA operation can be made in block or single modes.
    --
    -- For memory-to-memory transfers, the software request for channel 0 should be 
    -- set.
    --
    -- ??? From OKI 82C37 Datasheets ??? 
    -- All request bits are reset when the TC is reached, and when the request bit  
    -- of a certain channel has been received, all other request bits are cleared.
    --
    ---------------------------------------------------------------------------
    tcall <= tc(0) OR tc(1) OR tc(2) OR tc(3);  -- Any TC signal will clear the request register???
    process (reset,clk)
        begin
            if reset='1' then
                request_reg_s <= (others => '0');
            elsif falling_edge(clk) then
                if master_clear='1' OR (eop_latched='1' AND endbuscycle='1') or tcall='1' then
                    request_reg_s <= (others => '0');
                elsif wr='1' and abusl_in=WRITE_REQUEST_REG_C then  -- Write Single mask bit
                    case dbus_in(1 downto 0) is      -- You can only set 1 software request, right?
                       when "00"   => request_reg_s <= "000" & dbus_in(2); 
                       when "01"   => request_reg_s <= "00" & dbus_in(2) & '0';   
                       when "10"   => request_reg_s <= '0' & dbus_in(2) & "00";   
                       when others => request_reg_s <= dbus_in(2) & "000"; 
                    end case;
                end if;
            end if;
    end process;

    -- When reading the Request register, bits 4-7 will always read
    -- as ones, and bits 0-3 will display the request bits of channels
    -- 0-3 respectively.
    request_reg <= request_reg_s;   -- "1111" appended later on 
    
        
    ---------------------------------------------------------------------------
    -- Status Register
    -- Bits 0-3 are set by their respective TC signal or when EOP is applied
    -- Bits 0-3 are cleared upon RESET, Master_Clear and on a Status_read
    -- Bits 4-7 are cleared upon RESET, Master_Clear
    -- Bits 4-7 are set whenever their corresponding channel is requesting service,
    -- regardless of the mask bit state.
    --
    -- Version 1.3, add clr_status_reg_s signal
    -- The rd stobe is used to clear the status register, we need to delay 
    -- the clear operation until the processor has latched it.
    ---------------------------------------------------------------------------
    process (reset,clk)
        begin
            if reset='1' then
                status_reg <= (others => '0');
                clr_status_reg_s <= '0';
            elsif falling_edge(clk) then
                if master_clear='1' then
                    status_reg <= (others => '0');
                elsif rdpulse='1' AND clr_status_reg_s='1' then     -- Version 1.3
                    status_reg(3 downto 0) <= (others => '0');
                    clr_status_reg_s <= '0'; 
                elsif rd='1' AND abusl_in=READ_STATUS_REG_C then
                    --status_reg(3 downto 0) <= (others => '0');    -- Version 1.3
                    clr_status_reg_s <= '1';
                else
                    if (eop_in_s(0)='1' OR tc(0)='1') then status_reg(0)<= '1'; end if;
                    if (eop_in_s(1)='1' OR tc(1)='1') then status_reg(1)<= '1'; end if;
                    if (eop_in_s(2)='1' OR tc(2)='1') then status_reg(2)<= '1'; end if;
                    if (eop_in_s(3)='1' OR tc(3)='1') then status_reg(3)<= '1'; end if;
                    status_reg(7 downto 4) <= dreq_s;
                end if;
            end if;
    end process;

    ---------------------------------------------------------------------------
    -- DMA_Request signal
    -- request_reg_s(n) -> software request
    -- dreq_sense=0   -> DREQ=active high
    -- dreq_sense=1   -> DREQ=active low
    ---------------------------------------------------------------------------
    dreq_s(0) <= '1' when ((dreq(0)='1' AND dreq_sense_low='0') OR (dreq(0)='0' AND dreq_sense_low='1')) else '0';
    dreq_s(1) <= '1' when ((dreq(1)='1' AND dreq_sense_low='0') OR (dreq(1)='0' AND dreq_sense_low='1')) else '0';
    dreq_s(2) <= '1' when ((dreq(2)='1' AND dreq_sense_low='0') OR (dreq(2)='0' AND dreq_sense_low='1')) else '0';
    dreq_s(3) <= '1' when ((dreq(3)='1' AND dreq_sense_low='0') OR (dreq(3)='0' AND dreq_sense_low='1')) else '0';
    
    ---------------------------------------------------------------------------
    -- Signal must be latched after HLDA is asserted since the user can remove 
    -- DREQ after DACK
    ---------------------------------------------------------------------------
    dma_inp_s(0) <= '1' when request_reg_s(0)='1' OR (mask_reg_s(0)='0' AND dreq_s(0)='1') else '0';
    dma_inp_s(1) <= '1' when request_reg_s(1)='1' OR (mask_reg_s(1)='0' AND dreq_s(1)='1') else '0';
    dma_inp_s(2) <= '1' when request_reg_s(2)='1' OR (mask_reg_s(2)='0' AND dreq_s(2)='1') else '0';
    dma_inp_s(3) <= '1' when request_reg_s(3)='1' OR (mask_reg_s(3)='0' AND dreq_s(3)='1') else '0';
    
    ---------------------------------------------------------------------------
    -- Rotate Priority counter
    ---------------------------------------------------------------------------
    process (clk,reset)                                  -- Rotate Register                  
        begin
            if (reset='1') then                     
                rot <= (others => '0');              
            elsif falling_edge(clk) then 
                if master_clear='1' or rotate_priority='0' then 
                    rot <= (others => '0'); 
                else
                    if endbuscycle='1' then
                        case endbuscycle_s is 
                           when "0001"  => rot <= "01";  -- Last serviced CH0, CH1 is now the highest
                           when "0010"  => rot <= "10";  -- Last serviced CH1, CH2 is now the highest
                           when "0100"  => rot <= "11";  -- Last serviced CH2, CH3 is now the highest
                           when others  => rot <= "00";  -- Last serviced CH3, CH0 is now the highest
                        end case;

                        assert endbuscycle_s="0000" OR endbuscycle_s="0001" OR endbuscycle_s="0010" OR 
                               endbuscycle_s="0100" OR endbuscycle_s="1000" 
                               report "Multiple endbuscycle request, module dreqack" severity warning;
                    end if;
                end if;
            end if;   
    end process;    

    ---------------------------------------------------------------------------
    -- Select Highgest DREQ signal
    -- Fixed priority, rot=00, DREQ0=highest
    ---------------------------------------------------------------------------
    sel <= dma_inp_s & std_logic_vector(rot);
    process(sel,mem_2_mem,mem_chan,dma_inp_s)                  
        begin 
            if mem_2_mem='1' then
                dma_chan_s<='0' & mem_chan; dma_req_s<=dma_inp_s(0);
            else            
              case sel is 
                 -- dma_req(4)rot(2)
                 when "000100"  => dma_chan_s<="00"; dma_req_s<='1'; -- 0 highest priority
                 when "001000"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "001100"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "010000"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "010100"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "011000"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "011100"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "100000"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "100100"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "101000"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "101100"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "110000"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "110100"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "111000"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "111100"  => dma_chan_s<="00"; dma_req_s<='1'; 

                 when "000101"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "001001"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "001101"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "010001"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "010101"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "011001"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "011101"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "100001"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "100101"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "101001"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "101101"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "110001"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "110101"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "111001"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "111101"  => dma_chan_s<="01"; dma_req_s<='1'; 

                 when "000110"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "001010"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "001110"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "010010"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "010110"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "011010"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "011110"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "100010"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "100110"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "101010"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "101110"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "110010"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "110110"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "111010"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "111110"  => dma_chan_s<="10"; dma_req_s<='1'; 

                 when "000111"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "001011"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "001111"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "010011"  => dma_chan_s<="10"; dma_req_s<='1'; 
                 when "010111"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "011011"  => dma_chan_s<="01"; dma_req_s<='1'; 
                 when "011111"  => dma_chan_s<="00"; dma_req_s<='1'; 
                 when "100011"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "100111"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "101011"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "101111"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "110011"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "110111"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "111011"  => dma_chan_s<="11"; dma_req_s<='1'; 
                 when "111111"  => dma_chan_s<="11"; dma_req_s<='1'; 

                 when others    => dma_chan_s<="--"; dma_req_s<='0';
              end case;
            end if;
        end process;

        -----------------------------------------------------------------------
        -- Latch dma_chan and dma_req 
        -----------------------------------------------------------------------
        process (reset,clk)
            begin
                if reset='1' then
                    dma_chanl_s <= (others => '0');
                    dma_req     <= '0';
                    dma_reql_s  <= '0';
                elsif falling_edge(clk) then
                    if hrqn_s='1' then 
                        dma_chanl_s <= dma_chan_s;
                        dma_reql_s  <= dma_req_s;   -- Change for Cascade mode??
                    end if;

                    if aen_s='1' then
                        dma_req <= '0';
                    elsif hrqn_s='1' then 
                        dma_req <= dma_req_s;
                    end if;
                end if;
        end process;
        dma_req_mode0 <= dma_req_s;                 -- used for demand mode (see fsm37)
            
        -- Select Latched version for Mem2IO because DREQ is not always asserted
        dma_chan <= dma_chan_s when mem_2_mem='1' else dma_chanl_s;              
        
        -----------------------------------------------------------------------
        -- DMA_ACK signal      
        --
        -- Active Low after reset, can be changed to active high using command-
        -- reg bit 7.
        -- Enable DACK when not mem2mem, HLDA=1 and dma_reg='1'
        --
        -- Note that there is no DACK output signal during memory-memory
        -- transfers.
        --
        -- Memory-to-memory operations can be detected as an active AEN with no 
        -- DACK outputs.
        -----------------------------------------------------------------------
        dack(0) <= dack_active_high when (hlda='1' AND hrqn_s='0' AND dma_reql_s='1' AND dma_chanl_s="00" AND mem_2_mem='0') else NOT dack_active_high;
        dack(1) <= dack_active_high when (hlda='1' AND hrqn_s='0' AND dma_reql_s='1' AND dma_chanl_s="01" AND mem_2_mem='0') else NOT dack_active_high;
        dack(2) <= dack_active_high when (hlda='1' AND hrqn_s='0' AND dma_reql_s='1' AND dma_chanl_s="10") else NOT dack_active_high;
        dack(3) <= dack_active_high when (hlda='1' AND hrqn_s='0' AND dma_reql_s='1' AND dma_chanl_s="11") else NOT dack_active_high;


END ARCHITECTURE rtl;

