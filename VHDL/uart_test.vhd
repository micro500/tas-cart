--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:52:39 11/06/2013
-- Design Name:   
-- Module Name:   E:/FPGA/TAS-Cart/uart_test.vhd
-- Project Name:  TAS_Cart
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: UART
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
 
ENTITY uart_test IS
END uart_test;
 
ARCHITECTURE behavior OF uart_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT UART
    PORT(
         rx_data_out : OUT  std_logic_vector(7 downto 0);
         rx_data_was_recieved : IN  std_logic;
         rx_byte_waiting : OUT  std_logic;
         clk : IN  std_logic;
         rx_in : IN  std_logic;
         tx_data_in : IN  std_logic_vector(7 downto 0);
         tx_buffer_full : OUT  std_logic;
         tx_write : IN  std_logic;
         tx_out : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal rx_data_was_recieved : std_logic := '0';
   signal clk : std_logic := '0';
   signal rx_in : std_logic := '0';
   signal tx_data_in : std_logic_vector(7 downto 0) := (others => '0');
   signal tx_write : std_logic := '0';

 	--Outputs
   signal rx_data_out : std_logic_vector(7 downto 0);
   signal rx_byte_waiting : std_logic;
   signal tx_buffer_full : std_logic;
   signal tx_out : std_logic;

   -- Clock period definitions
   constant clk_period : time := 32 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: UART PORT MAP (
          rx_data_out => rx_data_out,
          rx_data_was_recieved => rx_data_was_recieved,
          rx_byte_waiting => rx_byte_waiting,
          clk => clk,
          rx_in => rx_in,
          tx_data_in => tx_data_in,
          tx_buffer_full => tx_buffer_full,
          tx_write => tx_write,
          tx_out => tx_out
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
