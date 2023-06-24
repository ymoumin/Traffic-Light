library ieee;
use ieee.std_logic_1164.all;

entity FSMUART is
	port (
		infoEtat :  in std_logic_vector(1 downto 0);
		UART_IRQ : in std_logic;
		RSC : in std_logic_vector(7 downto 0);
		ADDR2 : out std_logic_vector(1 downto 0);
		Rw : out std_logic;
		sel : out std_logic_vector(2 downto 0);
		RCC : out std_logic;
		Msg : out string(1 to 5);
end FSMUART;

architecture rtl of FSMUART is

component BAUD
	port(Sysclk, rst_b: in std_logic;
		Sel: in std_logic_vector(2 downto 0);
		BclkX8: buffer std_logic;
		Bclk: out std_logic);
end component;

component UART
	port (
		port (
		UART_sel, R_W, clk, rst_b, RxD : in std_logic;
	ADDR2: in std_logic_vector(1 downto 0);
	DBUS : inout std_logic_vector(7 downto 0);
	UART_IRQ, TxD : out std_logic);
end component;

component FSMController
port( 
		i_load: in std_logic;
		clk_G, reset_G : in std_logic;
		infoEtat :  out std_logic_vector(1 downto 0);
end component;

begin 

signal BaudSel : std_logic_vector(2 downto 0);
signal Bclk, BclkX8: std_logic;
signal Etat : std_logic_vector(1 downto 0);

VitesseBaud : BAUD port map(clk, rst_b, BaudSel, BclkX8, Bclk);

trafficlight : FSMController port map (1, Bclk, GReset, Etat);	

	process(Bclk)
begin

	if Etat = "00" then
		Msg <= "Pv_Lr";	 --ETAPE A
	elsif Etat = "01" then
		Msg <="Pj_Lr";		 --ETAPE B
	elsif Etat = "10" then
		Msg <="Pr_Lv";		 --ETAPE C
	elsif Etat = "11" then
		Msg <="Pv_Lj";		 --ETAPE D
	end if;

end process;

end rtl;