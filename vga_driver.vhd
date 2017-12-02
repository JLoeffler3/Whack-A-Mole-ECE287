----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:17:27 12/28/2016 
-- Design Name: 
-- Module Name:    vga_driver - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_driver is
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
			  MLE1 : in std_logic;
			  MLE2 : in std_logic;
			  MLE3 : in std_logic;
			  MLE4 : in std_logic;
			  MODE : in std_logic_vector(2 downto 0);
           HSYNC : out  STD_LOGIC;
           VSYNC : out  STD_LOGIC;
			  R : out std_logic_vector(7 downto 0);
			  G : out std_logic_vector(7 downto 0);
			  B : out std_logic_vector(7 downto 0);
			  VGA_CLOCK : out std_logic
			  );
end vga_driver;

architecture Behavioral of vga_driver is

	signal clk25 : std_logic := '0';
	
	constant HD : integer := 639;  --  639   Horizontal Display (640)
	constant HFP : integer := 16;         --   16   Right border (front porch)
	constant HSP : integer := 96;       --   96   Sync pulse (Retrace)
	constant HBP : integer := 48;        --   48   Left boarder (back porch)
	
	constant VD : integer := 479;   --  479   Vertical Display (480)
	constant VFP : integer := 10;       	 --   10   Right border (front porch)
	constant VSP : integer := 2;				 --    2   Sync pulse (Retrace)
	constant VBP : integer := 33;       --   33   Left boarder (back porch)
	
	signal hPos : integer := 0;
	signal vPos : integer := 0;
	
	signal videoOn : std_logic := '0';
	
	signal mh1 : integer := 300;
	signal mh2 : integer := 300;
	signal mh3 : integer := 300;
	signal mh4 : integer := 300;

	signal count : integer := 0;
	signal colorSet : std_logic;
	
	signal sinWave : integer := 0;
	signal sinWaveCounter : integer := 0;
	
	signal color : std_logic_vector(23 downto 0);
	signal colorcount : integer := 0;
	signal lerpDummy : std_logic;
	signal rd, gn, bl : std_logic_vector(7 downto 0) := "00000000";
	signal colorRun : integer := 1;
	
	--*****************COLOR FUNCTIONS***********************
	function hexToRGB(color : std_logic_vector(23 downto 0))return std_logic is
	begin
		R <= color(23 downto 16);
		G <= color(15 downto 8);
		B <= color(7 downto 0);
		return '1';
	end function hexToRGB;
	
	impure function Lerp(red, green, blue : std_logic_vector(7 downto 0) )return std_logic is
	begin
		if ( rd < red ) then
			rd <= rd + '1';
		end if;
		if ( rd > red ) then
			rd <= rd - '1';
		end if;
		if ( gn < green ) then
			gn <= gn + '1';
		end if;
		if ( gn > green ) then
			gn <= gn - '1';
		end if;

		if ( bl < blue ) then
			bl <= bl + '1';
		end if;
		if ( bl > blue ) then
			bl <= bl - '1';
		end if;
		R <= rd;
		G <= gn;
		B <= bl;
		return '1';
	end function Lerp;
	
	--*****************COLOR FUNCTIONS***********************
	
	--*****************DRAWING FUNCTIONS***********************
	impure function circle(rx, ry, x, y, r : integer) return std_logic is
	begin	
		if (rx - x)**2 + (ry - y)**2 < r*r then
			return '1';
		else
			return '0';
		end if;
	end circle;
	
	impure function rect(rx, ry, x, y, w, h : integer) return std_logic is
	begin	
		if ((rx <= (x + w) and rx >= x) and (ry <= (y + h) and ry >= y)) then
			return '1';
		else 
			return '0';
		end if;
	end rect;
	

	--*****************DRAWING FUNCTIONS***********************
		

begin


clk_div:process(CLK)
begin
	if(CLK'event and CLK = '1')then
		clk25 <= not clk25;
	end if;
end process;

VGA_CLOCK <= clk25;

Horizontal_position_counter:process(clk25, RST)
begin
	if(RST = '1')then
		hpos <= 0;
	elsif(clk25'event and clk25 = '1')then
		if (hPos = (HD + HFP + HSP + HBP)) then
			hPos <= 0;
		else
			hPos <= hPos + 1;
		end if;
	end if;
end process;

Vertical_position_counter:process(clk25, RST, hPos)
begin
	if(RST = '1')then
		vPos <= 0;
	elsif(clk25'event and clk25 = '1')then
		if(hPos = (HD + HFP + HSP + HBP))then
			if (vPos = (VD + VFP + VSP + VBP)) then
				vPos <= 0;
			else
				vPos <= vPos + 1;
			end if;
		end if;
	end if;
end process;

Horizontal_Synchronisation:process(clk25, RST, hPos)
begin
	if(RST = '1')then
		HSYNC <= '0';
	elsif(clk25'event and clk25 = '1')then
		if((hPos <= (HD + HFP)) OR (hPos > HD + HFP + HSP))then
			HSYNC <= '1';
		else
			HSYNC <= '0';
		end if;
	end if;
end process;

Vertical_Synchronisation:process(clk25, RST, vPos)
begin
	if(RST = '1')then
		VSYNC <= '0';
	elsif(clk25'event and clk25 = '1')then
		if((vPos <= (VD + VFP)) OR (vPos > VD + VFP + VSP))then
			VSYNC <= '1';
		else
			VSYNC <= '0';
		end if;
	end if;
end process;

video_on:process(clk25, RST, hPos, vPos)
begin
	if(RST = '1')then
		videoOn <= '0';
	elsif(clk25'event and clk25 = '1')then
		if(hPos <= HD and vPos <= VD)then
			videoOn <= '1';
		else
			videoOn <= '0';
		end if;
	end if;
end process;


draw:process(clk25, RST, hPos, vPos, videoOn, MLE1, MLE2, MLE3, MLE4)
begin
	if(RST = '1')then
		colorSet <= hexToRGB(x"000000");
	elsif(clk25'event and clk25 = '1')then
		if(videoOn = '1')then
			if MODE = "000" then
				count <= count + 1;
				if(rect(hpos, vpos, 75, 250, 100, 230) = '1')then
					colorSet <= hexToRGB(x"00FF00");
				elsif(circle(hpos, vpos, 125, mh1, 50) = '1' and MLE1 = '1')then
					colorSet <= hexToRGB(x"8B4513");
				elsif(rect(hpos, vpos, 200, 250, 100, 230) = '1')then
					colorSet <= hexToRGB(x"00FF00");
				elsif(circle(hpos, vpos, 250, mh2, 50) = '1' and MLE2 = '1')then
					colorSet <= hexToRGB(x"8B4513");
				elsif(rect(hpos, vpos, 325, 250, 100, 230) = '1')then
					colorSet <= hexToRGB(x"00FF00");
				elsif(circle(hpos, vpos, 375, mh3, 50) = '1' and MLE3 = '1')then
					colorSet <= hexToRGB(x"8B4513");
				elsif(rect(hpos, vpos, 450, 250, 100, 230) = '1')then
					colorSet <= hexToRGB(x"00FF00");
				elsif(circle(hpos, vpos, 500, mh4, 50) = '1' and MLE4 = '1')then
					colorSet <= hexToRGB(x"8B4513");
				else
					colorSet <= hexToRGB(x"123456");
				end if;
						
				if count >= 100000 then
					count <= 0;
					if MLE1 = '1' then
						mh1 <= mh1 - 1;
						if mh1 <= 250 then
							mh1 <= 250;
						end if;
					else
						mh1 <= 300;
					end if;
					if MLE2 = '1' then
						mh2 <= mh2 - 1;
						if mh2 <= 250 then
						
							mh2 <= 250;
						end if;
					else
						mh2 <= 300;
					end if;
					if MLE3 = '1' then
						mh3 <= mh3 - 1;
						if mh3 <= 250 then
							mh3 <= 250;
						end if;
					else
						mh3 <= 300;
					end if;
					if MLE4 = '1' then
						mh4 <= mh4 - 1;
						if mh4 <= 250 then
							mh4 <= 250;
						end if;
					else 
						mh4 <= 300;
					end if;
				end if;
			elsif MODE = "001" then
				if(rect(hpos, vpos, 75, 250, 100, 230) = '1')then
					colorSet <= hexToRGB(x"11FF65");
				else
					colorSet <= hexToRGB(x"123456");
				end if;
			elsif MODE = "010" then
				colorSet <= hexToRGB(color);
				colorcount <= colorCount + 1;
				if colorCount > 100000 then
					case (colorRun) is
						when 1 => 
							lerpDummy <= lerp(x"FF", x"00", x"00");
							if (rd = x"FF" and gn =  x"00" and bl = x"00") then
								colorRun <= colorRun + 1;
							end if;
						when 2 => 
							lerpDummy <= lerp(x"00", x"FF", x"00");
							if (rd = x"00" and gn =  x"FF" and bl = x"00") then
								colorRun <= colorRun + 1;
							end if;
						when 3 => 
							lerpDummy <= lerp(x"00", x"00", x"FF");
							if (rd = x"00" and gn =  x"00" and bl = x"FF") then
								colorRun <= colorRun + 1;
							end if;
						when 4 => 
							lerpDummy <= lerp(x"FF", x"FF", x"00");
							if (rd = x"FF" and gn =  x"FF" and bl = x"00") then
								colorRun <= colorRun + 1;
							end if;
						when 5 => 
							lerpDummy <= lerp(x"90", x"00", x"90");
							if (rd = x"90" and gn =  x"00" and bl = x"90") then
								colorRun <= colorRun + 1;
							end if;
						when 6 => 
							lerpDummy <= lerp(x"00", x"FF", x"FF");
							if (rd = x"00" and gn =  x"FF" and bl = x"FF") then
								colorRun <= colorRun + 1;
							end if;
						when others =>
							colorRun <= 1;
					end case;
					colorCount <= 0;
				end if;
			
			elsif MODE = "100" then
				colorSet <= hexToRGB(x"123456");
				for I in 0 to 639 loop
					if(rect(hpos, vpos, I, 240 + ((((4 * (I mod 180))*(180 - (I mod 180)))/(40500 - ((I mod 180) * (180 - (I mod 180)))))), 3, 3) = '1')then
						colorSet <= hexToRGB(x"11FF65");
					end if;
				end loop;

				
			else
				colorSet <= hexToRGB(x"123456");
				if(rect(hpos, vpos, sinWave, 200, 3, 3) = '1')then
						colorSet <= hexToRGB(x"11FF65");
				end if;
				sinWaveCounter <= sinWaveCounter + 1;
				if sinWaveCounter > 100 then
					sinWave <= sinWave + 1;
					if sinWave > 639 then
						sinWave <= 0;
					end if;
					sinWaveCounter <= 0;
				end if;
			end if;
		else
			colorSet <= hexToRGB(x"000000");
		end if;
	end if;
end process;


end Behavioral;

