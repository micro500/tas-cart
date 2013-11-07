--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:05:03 11/06/2013
-- Design Name:   
-- Module Name:   E:/FPGA/TAS-Cart/TAS-Cart_tb.vhd
-- Project Name:  TAS_Cart
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: TAS_Cart
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY TAS_Cart_tb IS
END TAS_Cart_tb;
 
ARCHITECTURE behavior OF TAS_Cart_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TAS_Cart
    PORT(
         CLK : IN  std_logic;
         ADDR : IN  std_logic_vector(14 downto 0);
         DATA : INOUT  std_logic_vector(7 downto 0);
         RW : IN  std_logic;
         M2 : IN  std_logic;
         CONSOLE_CE : IN  std_logic;
         CART_CE : OUT  std_logic;
         UART_RX : IN  std_logic;
         UART_TX : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal ADDR : std_logic_vector(14 downto 0) := (others => '0');
   signal RW : std_logic := '1';
   signal M2 : std_logic := '0';
   signal CONSOLE_CE : std_logic := '1';
   signal UART_RX : std_logic := '0';

	--BiDirs
   signal DATA : std_logic_vector(7 downto 0);

 	--Outputs
   signal CART_CE : std_logic;
   signal UART_TX : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 32 ns;
	
	constant console_clk_period : time := 46.560852 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: TAS_Cart PORT MAP (
          CLK => CLK,
          ADDR => ADDR,
          DATA => DATA,
          RW => RW,
          M2 => M2,
          CONSOLE_CE => CONSOLE_CE,
          CART_CE => CART_CE,
          UART_RX => UART_RX,
          UART_TX => UART_TX
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_period*10;
		
		wait for console_clk_period*6;
		
		M2 <= '0';		
		ADDR <= "000011111111010";
		
		wait for console_clk_period/2;
		DATA <= "11111111";
		wait for console_clk_period/2;
		
		wait for console_clk_period*3;	
		M2 <= '1';
		
		wait for console_clk_period*2;
		wait for console_clk_period*6;
		M2 <= '0';
		
		wait for 0.001ns;
		RW <= '0';
		
		wait for console_clk_period*4;
		M2 <= '1';
		
		wait for console_clk_period*2;
		DATA <= "00000001";
		
		wait for console_clk_period*6;
		M2 <= '0';
		wait for 0.001ns;
		RW <= '1';
		DATA <= "11111111";
		ADDR <= "000000000000000";
		
		
		
		
		wait for 1440 us;

      -- insert stimulus here 

      wait;
   end process;

END;
