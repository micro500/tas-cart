library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TAS_Cart is
    Port ( CLK  : in STD_LOGIC;
           ADDR : in STD_LOGIC_VECTOR(14 downto 0);
           DATA : inout STD_LOGIC_VECTOR(7 downto 0);
           RW   : in STD_LOGIC;
			  M2   : in STD_LOGIC;
			  CONSOLE_CE : in STD_LOGIC;
			  CART_CE : out STD_LOGIC;
			  UART_RX : in STD_LOGIC
			  );
end TAS_Cart;

architecture Behavioral of TAS_Cart is
	component UART is
    Port ( rx_data_out : out STD_LOGIC_VECTOR (7 downto 0);
           rx_data_was_recieved : in STD_LOGIC;
           rx_byte_waiting : out STD_LOGIC;
           clk : in  STD_LOGIC;
			  rx_in : in STD_LOGIC);
	end component;

--	signal counter : integer range 0 to 959 := 0;
--   signal cart_disabled : std_logic := '0';
	signal injecting : std_logic := '0';
	
	signal data_from_uart : STD_LOGIC_VECTOR (7 downto 0);
	signal uart_data_recieved : STD_LOGIC := '0';
	signal uart_byte_waiting : STD_LOGIC := '0';
begin

uart1: UART port map (rx_data_out => data_from_uart,
							 rx_data_was_recieved => uart_data_recieved,
							 rx_byte_waiting => uart_byte_waiting,
							 clk => CLK,
							 rx_in => UART_RX);




flash_led: process(M2)
	begin
		if (rising_edge(M2)) then
			if ('1' & ADDR = x"FFFA") then
				-- On the first NMI address read, toggle our state
				if (uart_byte_waiting = '1') then
					if (data_from_uart = x"31") then
						injecting <= '0';
					else
						injecting <= '1';
					end if;
					uart_data_recieved <= '1';
				else
					injecting <= '1';
					uart_data_recieved <= '0';
				end if;
			else
				uart_data_recieved <= '0';
			end if;
		end if;
	end process;

CART_CE <= '1' when (injecting = '1' and ('1' & ADDR = x"FFFA" or '1' & ADDR = x"FFFB" or '1' & ADDR = x"8000")) else
           CONSOLE_CE;

DATA <= "01000000" when (injecting = '1' and '1' & ADDR = x"8000" and RW = '1') else
        "00000000" when (injecting = '1' and not CONSOLE_CE & ADDR = x"FFFA" and RW = '1') else
        "10000000" when (injecting = '1' and not CONSOLE_CE & ADDR = x"FFFB" and RW = '1') else
        --"10000010" when (injecting = '0' and not CONSOLE_CE & ADDR = x"FFFA" and RW = '1') else
        --"10000000" when (injecting = '0' and not CONSOLE_CE & ADDR = x"FFFB" and RW = '1') else
        "ZZZZZZZZ";

end Behavioral;

