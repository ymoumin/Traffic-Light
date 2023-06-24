LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY FSMController IS
	PORT(
		SSCS, i_load: in std_logic; -- counter load <---------------- DEFINE
		clk_G, reset_G : in std_logic;
		MSTL, SSTL : out std_logic_vector(2 downto 0);
		BCD1, BCD2 : out std_logic_vector(3 downto 0); -- DECODEUR A BCD
		infoEtat :  out std_logic_vector(1 downto 0));
END FSMController;   

ARCHITECTURE rtl OF FSMController IS
	
	COMPONENT enARdFF_2
		PORT(
			i_resetBar	: IN	STD_LOGIC;
			i_d		: IN	STD_LOGIC;
			i_enable	: IN	STD_LOGIC;
			i_clock		: IN	STD_LOGIC;
			o_q, o_qBar	: OUT	STD_LOGIC);
	END COMPONENT;
	
	COMPONENT FSMUART
	port (
		infoEtat :  in std_logic_vector(1 downto 0);
		IRQ : in std_logic;
		RSC : in std_logic_vector(7 downto 0);
		Adds : out std_logic_vector(1 downto 0);
		Rw : out std_logic;
		sel : out std_logic_vector(2 downto 0);
		RCC : out std_logic;
		str : out string(1 to 5 );
end COMPONENT;
	
	signal int_x1, int_x0, int_ny1, int_ny0, int_y1, int_y0, int_noty1, int_noty0 : std_logic;
	signal int_z5, int_z3, int_z2, int_z1, int_z0 : std_logic;
	
BEGIN

-- INPUTS
	int_x0 = SSCS;
	int_x1 = i_load;

-- NEXT STATE
	int_ny1 = (int_x0 and int_y0) xor int_y1;
	int_ny0 = (not(int_x0) and int_y0) or (int_x0 and int_y1 and not(int_y0)) or (int_x1 and int_x0 and not(int_y0));
	
-- OUTPUT
	int_z5 = int_ny1;
	int_z4 = (not(int_x0 and not(int_y1) and int_y0)) or (int_x1 and not(int_y1) and not(int_y0));
	int_z3 = (not(int_x1) and not(int_y1)) or (not(int_x0 and not(int_y1) and not(int_y0))) or (int_x0 and int_y1 and int_y0);
	int_z2 = not(int_ny1);
	int_z1 = int_y1 and (int_x0 xor int_y0);
	int_z0 = (not(int_x0) and int_y1 and not(int_y0)) or (int_x0 and not(int_y1) and int_y0);
	
Y1: enARdFF_2
	PORT MAP (i_resetBar => reset_G,
			  i_d => int_ny1,
			  i_enable => i_load, 
			  i_clock => i_clock,
			  o_q => int_y1,
	          o_qBar => int_noty1);

Y0: enARdFF_2
	PORT MAP (i_resetBar => reset_G,
			  i_d => int_ny0, 
			  i_enable => i_load,
			  i_clock => i_clock,
			  o_q => int_y0,
	          o_qBar => int_noty0);
	
	infoEtat(1) <= int_ny1;
	infoEtat(0) <= int_ny0;
	MSTL(2) <= int_z5;
	MSTL(1) <= int_z4;
	MSTL(0) <= int_z3;
	SSTL(2) <= int_z2;
	SSTL(1) <= int_z1;
	SSTL(0) <= int_z0;

END rtl;
