------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                             S Y S T E M . I N I T                        --
--                                                                          --
--                                   S p e c                                --
--                                                                          --
--          Copyright (C) 2003-2025, Free Software Foundation, Inc.         --
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
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by AdaCore.                        --
--                                                                          --
------------------------------------------------------------------------------

--  This unit contains initialization circuits that are system dependent

--  This package is for use with configurable runtimes, and replaces init.c

pragma Restrictions (No_Elaboration_Code);
--  The procedure Install_Handler is called by the binder generated file before
--  any elaboration code, so we use the No_Elaboration_Code restriction to be
--  enfore full static preelaboration.

package System.Init is
   pragma Preelaborate;

   procedure Runtime_Initialize (Install_Handler : Integer);
   pragma Export (C, Runtime_Initialize, "__gnat_runtime_initialize");
   --  This procedure is called by adainit before the elaboration of other
   --  units. It usually installs handler for the synchronous signals. The C
   --  profile here is what is expected by the binder-generated main.

   procedure Runtime_Finalize;
   pragma Export (C, Runtime_Finalize, "__gnat_runtime_finalize");
   --  This procedure is called by adafinal.

end System.Init;
