library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity TAS_Cart is
    Port ( CLK  : in STD_LOGIC;
           ADDR : in STD_LOGIC_VECTOR(14 downto 0);
           DATA : inout STD_LOGIC_VECTOR(7 downto 0);
           RW   : in STD_LOGIC;
			  M2   : in STD_LOGIC;
			  CONSOLE_CE : in STD_LOGIC;
			  CART_CE : out STD_LOGIC;
			  UART_RX : in STD_LOGIC;
			  UART_TX : out STD_LOGIC;
			  LED1 : out STD_LOGIC;
			  LEDs : out STD_LOGIC_VECTOR (3 downto 0)
			  );
end TAS_Cart;

architecture Behavioral of TAS_Cart is
	component UART is
    Port ( rx_data_out : out STD_LOGIC_VECTOR (7 downto 0);
           rx_data_was_recieved : in STD_LOGIC;
           rx_byte_waiting : out STD_LOGIC;
           clk : in  STD_LOGIC;
			  
			  rx_in : in STD_LOGIC;
			  tx_data_in : in STD_LOGIC_VECTOR (7 downto 0);
           tx_buffer_full : out STD_LOGIC;
           tx_write : in STD_LOGIC;
			  tx_out : out STD_LOGIC);
	end component;
	
	COMPONENT state_memory
	  PORT (
		 clka : IN STD_LOGIC;
		 ena : IN STD_LOGIC;
		 wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		 addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
		 dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		 douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	  );
	END COMPONENT;

--	signal counter : integer range 0 to 959 := 0;
--   signal cart_disabled : std_logic := '0';
	signal injecting : std_logic := '0';
	
	signal data_from_uart : STD_LOGIC_VECTOR (7 downto 0);
	signal uart_data_recieved : STD_LOGIC := '0';
	signal uart_byte_waiting : STD_LOGIC := '0';
	
	signal data_to_uart : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	signal uart_buffer_full : STD_LOGIC;
	signal uart_write : STD_LOGIC := '0';
	
	signal save_state_requested : STD_LOGIC := '0';
	signal save_state_flag : STD_LOGIC := '0';
	
	type savestate_state_type is (IDLE,WAITNMI,SAVING,SENDING,WAITFINISH1,WAITFINISH2);
	signal savestate_state : savestate_state_type := IDLE;
	signal savestate_NS : savestate_state_type := IDLE;
	
	signal NMI_Trigger : STD_LOGIC := '0';
	
	signal done_saving_state : STD_LOGIC := '0';
	signal done_sending_state : STD_LOGIC := '0';
	signal finish_sending_state : STD_LOGIC := '0';
	
	signal state_memory_en : STD_LOGIC := '0';
	signal state_memory_wen : STD_LOGIC_VECTOR(0 downto 0) := "0";
	signal state_memory_dout : STD_LOGIC_VECTOR(7 downto 0);
	
	signal sending_state : STD_LOGIC := '0';
	signal sending_addr : STD_LOGIC_VECTOR(10 downto 0) := "00000000000";
	
	signal addr_for_bram : STD_LOGIC_VECTOR(10 downto 0);
	signal data_for_bram : STD_LOGIC_VECTOR(7 downto 0);
	
	signal currently_sending : STD_LOGIC := '0';
begin

uart1: UART port map (rx_data_out => data_from_uart,
							 rx_data_was_recieved => uart_data_recieved,
							 rx_byte_waiting => uart_byte_waiting,
							 clk => CLK,
							 rx_in => UART_RX,
							 tx_data_in => data_to_uart,
							 tx_buffer_full => uart_buffer_full,
							 tx_write => uart_write,
							 tx_out => UART_TX);

state_memory1 : state_memory
  PORT MAP (
    clka => clk,
    ena => state_memory_en,
    wea => state_memory_wen,
    addra => addr_for_bram,
    dina => data_for_bram,
    douta => state_memory_dout
  );




--frame_advance: process(M2)
--	begin
--		if (rising_edge(M2)) then
--			if ('1' & ADDR = x"FFFA") then
--				-- On the first NMI address read, toggle our state
--				if (uart_byte_waiting = '1') then
--					if (data_from_uart = x"31") then
--						injecting <= '0';
--					else
--						injecting <= '1';
--					end if;
--					uart_data_recieved <= '1';
--				else
--					injecting <= '1';
--					uart_data_recieved <= '0';
--				end if;
--			else
--				uart_data_recieved <= '0';
--			end if;
--		end if;
--	end process;

--send_time_digit: process(M2)
--	begin
--		if (falling_edge(M2)) then
--			if (not CONSOLE_CE & ADDR = x"07FA" and RW = '0' and uart_buffer_full = '0') then
--				data_to_uart <= "0011" & DATA(3 downto 0);
--				uart_write <= '1';
--			else
--				uart_write <= '0';
--			end if;
--		end if;
--	end process;

recieve_btye: process(CLK)
	begin
		if (rising_edge(CLK)) then
			if (uart_byte_waiting = '1') then
				if (data_from_uart = x"73") then -- 's'
					save_state_requested <= '1';
				end if;
				uart_data_recieved <= '1';
			else
				save_state_requested <= '0';
				uart_data_recieved <= '0';
			end if;
		end if;
	end process;
	
save_state_sync: process(clk, savestate_NS)
	begin
		if (rising_edge(CLK)) then
			savestate_state <= savestate_NS;
		end if;
	end process;

save_state_proc: process(savestate_state, save_state_requested, NMI_Trigger, done_saving_state, done_sending_state, finish_sending_state)
	begin
		case savestate_state is
			when IDLE =>
				injecting <= '0';
				LED1 <= '1';
				LEDs <= "0000";
				if (save_state_requested = '1') then savestate_NS <= WAITNMI;
				else savestate_NS <= IDLE;
				end if;
			when WAITNMI =>
				injecting <= '1';
				LED1 <= '1';
				LEDs <= "1000";
				if (NMI_Trigger = '1') then savestate_NS <= SAVING;
				else savestate_NS <= WAITNMI;
				end if;
			when SAVING =>
				injecting <= '1';
				LED1 <= '1';
				LEDs <= "0100";
				if (done_saving_state = '1') then savestate_NS <= WAITFINISH1;
				else savestate_NS <= SAVING;
				end if;
			when SENDING =>
				injecting <= '1';
				LED1 <= '0';
				LEDs <= "0000";
				if (done_sending_state = '1') then savestate_NS <= WAITFINISH1;
				else savestate_NS <= SENDING;
				end if;
			when WAITFINISH1 =>
				injecting <= '1';
				LED1 <= '1';
				LEDs <= "0010";
				if (finish_sending_state = '1') then savestate_NS <= WAITFINISH2;
				else savestate_NS <= WAITFINISH1;
				end if;
			when WAITFINISH2 =>
				injecting <= '1';
				LED1 <= '0';
				LEDs <= "0001";
				if (finish_sending_state = '0') then savestate_NS <= IDLE;
				else savestate_NS <= WAITFINISH2;
				end if;
		end case;
	end process;

NMI_Trigger <= '1' when (not CONSOLE_CE & ADDR = x"FFFA" and M2 = '1' and RW = '1') else
					'0';

done_saving_state <= '1' when (savestate_state = SAVING and not CONSOLE_CE & ADDR = x"9022" and RW = '1' and M2 = '1') else
							'0';
							
finish_sending_state <= '1' when ((savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2) and not CONSOLE_CE & ADDR = x"9024" and RW = '1') else
								'0';

save_sender: process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (currently_sending = '0' and savestate_state = SENDING) then
				currently_sending <= '1';
				sending_addr <= std_logic_vector(to_unsigned(0,sending_addr'length));
				uart_write <= '1';
				done_sending_state <= '0';
			elsif (currently_sending = '1' and uart_buffer_full = '0') then
				if (sending_addr = "11111111111") then
					currently_sending <= '0';
					done_sending_state <= '1';
				else
					sending_addr <= std_logic_vector(to_unsigned(to_integer(unsigned(sending_addr)) + 1,sending_addr'length));
					uart_write <= '1';
				end if;
			else
				uart_write <= '0';
				done_sending_state <= '0';
			end if;
		end if;
	end process;
	
data_to_uart <= state_memory_dout;

data_for_bram <= DATA when (injecting = '1' and savestate_state = SAVING) else
					  "11111111";

-- Use the ADDR bus for the BRAM when saving, otherwise use the manual signal
addr_for_bram <= ADDR(10 downto 0) when savestate_state = SAVING else
					  sending_addr;

-- Writing to BRAM is enabled if: mode is saving, high M2, bus is writing, and the address is 0x8000-0x87FF
state_memory_wen <= "1" when (savestate_state = SAVING and M2 = '1' and RW = '0' and not CONSOLE_CE & ADDR(14 downto 11) = "10000") else
						  "0";

-- BRAM is enabled when saving state or sending state
state_memory_en <= '1' when (savestate_state = SAVING or savestate_state = SENDING) else
						 '0';


CART_CE <= '1' when (injecting = '1' and (not CONSOLE_CE & ADDR = x"FFFA" or
														not CONSOLE_CE & ADDR = x"FFFB" or
														
--														((not CONSOLE_CE & ADDR(14 downto 5) = "10010000000" or -- 0x9000 - 0x901F
--														not CONSOLE_CE & ADDR = x"9020" or
--														not CONSOLE_CE & ADDR = x"9021" or
--														not CONSOLE_CE & ADDR = x"9022" or
--														not CONSOLE_CE & ADDR = x"9023" or
--														not CONSOLE_CE & ADDR = x"9024" or
--														not CONSOLE_CE & ADDR = x"9025" or
--														not CONSOLE_CE & ADDR = x"9026") 
														((not CONSOLE_CE & ADDR = x"9000" or
														  not CONSOLE_CE & ADDR = x"9001" or
														  not CONSOLE_CE & ADDR = x"9002" or
														  not CONSOLE_CE & ADDR = x"9003" or
														  not CONSOLE_CE & ADDR = x"9004" or
														  not CONSOLE_CE & ADDR = x"9005" or
														  not CONSOLE_CE & ADDR = x"9006" or
														  not CONSOLE_CE & ADDR = x"9007" or
														  not CONSOLE_CE & ADDR = x"9008" or
														  not CONSOLE_CE & ADDR = x"9009" or
														  not CONSOLE_CE & ADDR = x"900A" or
														  not CONSOLE_CE & ADDR = x"900B" or
														  not CONSOLE_CE & ADDR = x"900C" or
														  not CONSOLE_CE & ADDR = x"900D" or
														  not CONSOLE_CE & ADDR = x"900E" or
														  not CONSOLE_CE & ADDR = x"900F" or
														  not CONSOLE_CE & ADDR = x"9010" or
														  not CONSOLE_CE & ADDR = x"9011" or
														  not CONSOLE_CE & ADDR = x"9012" or
														  not CONSOLE_CE & ADDR = x"9013" or
														  not CONSOLE_CE & ADDR = x"9014" or
														  not CONSOLE_CE & ADDR = x"9015" or
														  not CONSOLE_CE & ADDR = x"9016" or
														  not CONSOLE_CE & ADDR = x"9017" or
														  not CONSOLE_CE & ADDR = x"9018" or
														  not CONSOLE_CE & ADDR = x"9019" or
														  not CONSOLE_CE & ADDR = x"901A" or
														  not CONSOLE_CE & ADDR = x"901B" or
														  not CONSOLE_CE & ADDR = x"901C" or
														  not CONSOLE_CE & ADDR = x"901D" or
														  not CONSOLE_CE & ADDR = x"901E" or
														  not CONSOLE_CE & ADDR = x"901F" or
														  not CONSOLE_CE & ADDR = x"9020" or
														  not CONSOLE_CE & ADDR = x"9021" or
														  not CONSOLE_CE & ADDR = x"9022" or
														  not CONSOLE_CE & ADDR = x"9023")
														and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) )) else
           CONSOLE_CE;

DATA <= "00000000" when (injecting = '1' and not CONSOLE_CE & ADDR = x"FFFA" and RW = '1') else  -- Set NMI Address to 0x9000
		  "10010000" when (injecting = '1' and not CONSOLE_CE & ADDR = x"FFFB" and RW = '1') else
		  
--        x"EA"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9000" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- NOP
--		  x"40"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9001" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- RTI
		  
		  
		  
		  x"A0"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9000" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- LDY #$FF
		  x"FF"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9001" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"A9"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9002" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- LDA #$00
		  x"00"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9003" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"8D"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9004" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- STA $0004
		  x"04"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9005" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"00"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9006" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"A2"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9007" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- LDX #$87
		  x"87"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9008" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"8E"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9009" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- STX $0005
		  x"05"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"900A" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"00"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"900B" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"A2"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"900C" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- LDX #$07
		  x"07"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"900D" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"8D"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"900E" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- STA $0006
		  x"06"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"900F" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"00"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9010" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else 
		  x"8E"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9011" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- STX $0007 (loop start)
		  x"07"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9012" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"00"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9013" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"B1"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9014" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- LDA ($06),Y (loop2)
		  x"06"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9015" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  
--		  --x"91"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9016" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- STA ($08),Y
--		  --x"08"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9017" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  
		  x"EA"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9016" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- NOP
		  x"EA"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9017" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else	-- NOP
		  
		  x"88"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9018" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- DEY
		  x"C0"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9019" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- CPY #$FD
		  x"FD"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"901A" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"D0"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"901B" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- BNE loop2
		  x"F7"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"901C" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"CE"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"901D" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- DEC $0005
		  x"05"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"901E" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"00"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"901F" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else
		  x"CA"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9020" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- DEX
		  
		  x"EA"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9021" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- NOP
		  x"EA"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9022" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- NOP
		  x"40"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9023" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- RTI
		  
--		  x"10"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9021" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- BPL loop start
--		  x"EE"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9022" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  
--		  
--		  x"40"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9023" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING or (savestate_state = WAITFINISH1 or savestate_state = WAITFINISH2))) else  -- RTI
--		  
----		  x"4C"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9023" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING)) else  -- JMP $9023 (infinite loop while saving or sending))
----		  x"23"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9024" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING)) else
----		  x"90"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9025" and RW = '1' and (savestate_state = SAVING or savestate_state = SENDING)) else
----		  
----		  x"EA"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9023" and RW = '1' and savestate_state = WAITFINISH) else  -- NOP
----		  x"EA"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9024" and RW = '1' and savestate_state = WAITFINISH) else  -- NOP
----		  x"EA"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9025" and RW = '1' and savestate_state = WAITFINISH) else  -- NOP
----		  x"40"      when (injecting = '1' and not CONSOLE_CE & ADDR = x"9026" and RW = '1' and savestate_state = WAITFINISH) else  -- RTI (we're done when finished sending)
		  "ZZZZZZZZ";
		  

end Behavioral;

