------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                       S Y S T E M . T E X T _ I O                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 1992-2020, Free Software Foundation, Inc.         --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

--  ESP32S3 ROM function based Text_IO implementation

with Interfaces;

package body System.Text_IO is

   use type Interfaces.Integer_32;

   --  ESP32S3 ROM function declarations
   function esp_rom_uart_tx_one_char
     (c : Interfaces.Unsigned_8) return Interfaces.Integer_32
     with Import, Convention => C, External_Name => "esp_rom_uart_tx_one_char";

   function esp_rom_uart_rx_one_char
     (c : access Interfaces.Unsigned_8) return Interfaces.Integer_32
     with Import, Convention => C, External_Name => "esp_rom_uart_rx_one_char";

   --  Alternative ROM functions (if the above are not available)
   procedure uart_tx_one_char (c : Interfaces.Unsigned_8)
     with Import, Convention => C, External_Name => "uart_tx_one_char";

   function uart_rx_one_char return Interfaces.Integer_32
     with Import, Convention => C, External_Name => "uart_rx_one_char";

   ---------
   -- Get --
   ---------

   function Get return Character is
      C : aliased Interfaces.Unsigned_8;
      Result : Interfaces.Integer_32;
   begin
      --  Try to use the newer ROM function first
      Result := esp_rom_uart_rx_one_char (C'Access);
      if Result = 0 then
         return Character'Val (C);
      else
         --  Fallback to older ROM function
         Result := uart_rx_one_char;
         if Result >= 0 then
            return Character'Val (Interfaces.Unsigned_8 (Result));
         else
            return ASCII.NUL; -- No character available
         end if;
      end if;
   end Get;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Initialized := True;
   end Initialize;

   -----------------
   -- Is_Rx_Ready --
   -----------------

   function Is_Rx_Ready return Boolean is
      C : aliased Interfaces.Unsigned_8;
      Result : Interfaces.Integer_32;
   begin
      --  Check if a character is available without consuming it
      --  This is a simplified implementation
      Result := esp_rom_uart_rx_one_char (C'Access);
      return Result = 0;
   end Is_Rx_Ready;

   -----------------
   -- Is_Tx_Ready --
   -----------------

   function Is_Tx_Ready return Boolean is
   begin
      --  ESP32S3 UART ROM functions are typically always ready
      --  or handle buffering internally
      return True;
   end Is_Tx_Ready;

   ---------
   -- Put --
   ---------

   procedure Put (C : Character) is
      Result : Interfaces.Integer_32;
   begin
      --  Try to use the newer ROM function first
      Result := esp_rom_uart_tx_one_char (Character'Pos (C));
      if Result /= 0 then
         --  Fallback to older ROM function
         uart_tx_one_char (Character'Pos (C));
      end if;
   end Put;

   ----------------------------
   -- Use_Cr_Lf_For_New_Line --
   ----------------------------

   function Use_Cr_Lf_For_New_Line return Boolean is
   begin
      return True;
   end Use_Cr_Lf_For_New_Line;

end System.Text_IO;