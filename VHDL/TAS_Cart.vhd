library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TAS_Cart is
    Port ( --CLK  : in STD_LOGIC;
           ADDR : in STD_LOGIC_VECTOR(14 downto 0);
           DATA : inout STD_LOGIC_VECTOR(7 downto 0);
           RW   : in STD_LOGIC;
			  M2   : in STD_LOGIC;
			  CONSOLE_CE : in STD_LOGIC;
			  CART_CE : out STD_LOGIC
--			  LED1 : out STD_LOGIC
			  );
end TAS_Cart;

architecture Behavioral of TAS_Cart is
--	signal counter : integer range 0 to 959 := 0;
--	signal led_output : std_logic := '0';
--   signal cart_disabled : std_logic := '0';
	signal injecting : std_logic := '0';
begin

--LED1 <= led_output;

flash_led: process(M2)
	begin
		if (rising_edge(M2)) then
			if ('1' & ADDR = x"FFFA") then
				-- On the first NMI address read, toggle our state
				injecting <= not injecting;
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

