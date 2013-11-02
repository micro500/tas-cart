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
			  UART_RX : in STD_LOGIC;
			  LED1 : out STD_LOGIC
			  );
end TAS_Cart;

architecture Behavioral of TAS_Cart is
--	signal counter : integer range 0 to 959 := 0;
	signal baud_counter : integer range 0 to 1627 := 0;
	signal rx_bit_buffer : std_logic_vector (39 downto 0) := (others => '1');
	signal led_output : std_logic := '0';
--   signal cart_disabled : std_logic := '0';
	signal injecting : std_logic := '0';
	signal baud : std_logic := '0';
	signal recent_rx_val : std_logic_vector(7 downto 0);
begin

baud_generator: process (CLK)
	begin
		if rising_edge(CLK) then
			if (baud_counter = 407) then
				baud <= not baud;
				baud_counter <= 0;
			else
				baud_counter <= baud_counter + 1;
			end if;
		end if;
	end process;

RX_bit: process (baud)
	begin
		if rising_edge(baud) then
			if (rx_bit_buffer(38 downto 37) = "11" and
			    rx_bit_buffer(34) = rx_bit_buffer(33) and
				 rx_bit_buffer(30) = rx_bit_buffer(29) and
				 rx_bit_buffer(26) = rx_bit_buffer(25) and
				 rx_bit_buffer(22) = rx_bit_buffer(21) and
				 rx_bit_buffer(18) = rx_bit_buffer(17) and
				 rx_bit_buffer(14) = rx_bit_buffer(13) and
				 rx_bit_buffer(10) = rx_bit_buffer(9) and
				 rx_bit_buffer(6) = rx_bit_buffer(5) and
				 rx_bit_buffer(2 downto 1) = "00") then
				 recent_rx_val <= rx_bit_buffer(34) & rx_bit_buffer(30) & rx_bit_buffer(26) & rx_bit_buffer(22) & rx_bit_buffer(18) & rx_bit_buffer(14) & rx_bit_buffer(10) & rx_bit_buffer(6);
				 led_output <= not led_output;
				 rx_bit_buffer <= (others => '1');
			else
				rx_bit_buffer <= UART_RX & rx_bit_buffer(39 downto 1);
			end if;
		end if;
	end process;
	
LED1 <= led_output;

flash_led: process(M2)
	begin
		if (rising_edge(M2)) then
			if ('1' & ADDR = x"FFFA") then
				-- On the first NMI address read, toggle our state
				if (recent_rx_val = x"31") then
					injecting <= not injecting;
				else
					injecting <= '0';
				end if;
			end if;
		end if;
	end process;

CART_CE <= '1' when (injecting = '1' and ('1' & ADDR = x"FFFA" or '1' & ADDR = x"FFFB" or '1' & ADDR = x"8000")) else
           CONSOLE_CE;

DATA <= "01000000" when (injecting = '1' and '1' & ADDR = x"8000" and RW = '1') else
        "00000000" when (injecting = '1' and not CONSOLE_CE & ADDR = x"FFFA" and RW = '1') else
        "10000000" when (injecting = '1' and not CONSOLE_CE & ADDR = x"FFFB" and RW = '1') else
        "10000010" when (injecting = '0' and not CONSOLE_CE & ADDR = x"FFFA" and RW = '1') else
        "10000000" when (injecting = '0' and not CONSOLE_CE & ADDR = x"FFFB" and RW = '1') else
        "ZZZZZZZZ";

end Behavioral;

