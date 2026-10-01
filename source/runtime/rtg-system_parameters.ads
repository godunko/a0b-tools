--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with RTG.Runtime;

package RTG.System_Parameters is

   type System_Parameters_Variant is
     (Non_Tasking, Embedded_Tasking, Full_Tasking);

   type System_Parameters_Descriptor is record
      Variant                          : System_Parameters_Variant;

      Stack_Grows_Down                 : Boolean;
      Runtime_Default_Sec_Stack_Size   : Natural;

      --  Tasking parameters

      Default_Stack_Size               : Natural;
      Minimum_Stack_Size               : Natural;
      Garbage_Collected                : Boolean;
      No_Abort                         : Boolean;
      Max_Attribute_Count              : Natural;
      Max_Task_Image_Length            : Natural;
      Default_Exception_Msg_Max_Length : Natural;

      --  Full tasking parameters

      Default_Env_Stack_Size           : Natural;
      Sec_Stack_Dynamic                : Boolean;
   end record;

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Parameters : System_Parameters_Descriptor);

end RTG.System_Parameters;
