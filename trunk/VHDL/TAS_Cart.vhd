library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TAS_Cart is
    Port ( --CLK  : in STD_LOGIC;
           ADDR : in STD_LOGIC_VECTOR(14 downto 0);
           DATA : out STD_LOGIC_VECTOR(7 downto 0);
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
   signal cart_disabled : std_logic := '0';
begin

--LED1 <= led_output;

flash_led: process(M2)
	begin
		if (rising_edge(M2)) then
			if ('1' & ADDR = x"FFFA" or '1' & ADDR = x"FFFB") then
				cart_disabled <= '1';
			else
				cart_disabled <= '0';
			end if;
		end if;
	end process;

CART_CE <= CONSOLE_CE when cart_disabled = '0' else
			  '1';

DATA <= "10000010" when (cart_disabled = '1' and not CONSOLE_CE & ADDR = x"FFFA" and RW = '1') else
        "10000000" when (cart_disabled = '1' and not CONSOLE_CE & ADDR = x"FFFB" and RW = '1') else
        "ZZZZZZZZ";

end Behavioral;

