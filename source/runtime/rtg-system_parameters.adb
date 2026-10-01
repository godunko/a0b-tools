--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Formatters.Integers;
with VSS.Strings.Templates;

with RTG.Utilities;

package body RTG.System_Parameters is

   procedure Generate_Specification
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Parameters : System_Parameters_Descriptor);

   procedure Generate_Body
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Parameters : System_Parameters_Descriptor);

   -------------------
   -- Generate_Body --
   -------------------

   procedure Generate_Body
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Parameters : System_Parameters_Descriptor)
   is
      use VSS.Strings.Templates;

      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Aux_Runtime_Source_Directory, "s-parame.adb");
      use Output;

      Return_Default_Template : constant Virtual_String_Template :=
        "         return {};";

   begin
      NL;
      PL ("package body System.Parameters is");
      NL;
      PL ("   function Default_Stack_Size return Size_Type is");
      PL ("      Default_Stack_Size : constant Integer;");
      PL ("      pragma Import (C, Default_Stack_Size, ""__gl_default_stack_size"");");
      PL ("   begin");
      PL ("      if Default_Stack_Size = -1 then");
      PL
        (Return_Default_Template.Format
           (VSS.Strings.Formatters.Integers.Image
              (Parameters.Default_Stack_Size)));
      PL ("      elsif Size_Type (Default_Stack_Size) < Minimum_Stack_Size then");
      PL ("         return Minimum_Stack_Size;");
      PL ("      else");
      PL ("         return Size_Type (Default_Stack_Size);");
      PL ("      end if;");
      PL ("   end Default_Stack_Size;");

      NL;
      PL ("end System.Parameters;");
   end Generate_Body;

   ----------------------------
   -- Generate_Specification --
   ----------------------------

   procedure Generate_Specification
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Parameters : System_Parameters_Descriptor)
   is
      use VSS.Strings.Templates;

      package Output is
        new RTG.Utilities.Generic_Output
          (Runtime.Aux_Runtime_Source_Directory, "s-parame.ads");
      use Output;

      Runtime_Default_Sec_Stack_Size_Template : constant
        Virtual_String_Template :=
          "   Runtime_Default_Sec_Stack_Size : constant Size_Type := {};";
      Default_Exception_Msg_Max_Length_Template : constant
        Virtual_String_Template :=
          "   Default_Exception_Msg_Max_Length : constant := {};";
      Max_Task_Image_Length_Template : constant
        Virtual_String_Template :=
          "   Max_Task_Image_Length : constant := {};";
      Max_Attribute_Count_Template : constant
        Virtual_String_Template :=
          "   Max_Attribute_Count : constant := {};";
      Default_Stack_Size_Template : constant Virtual_String_Template :=
        "   Default_Stack_Size : constant Size_Type := {};";
      Minimum_Stack_Size_Parameter_Template : constant
        Virtual_String_Template :=
          "   Minimum_Stack_Size : constant Size_Type := {};";
      Minimum_Stack_Size_Function_Template : constant
        Virtual_String_Template :=
          "   function Minimum_Stack_Size return Size_Type is ({});";

   begin
      NL;
      PL ("package System.Parameters with Pure is");

      NL;
      PL ("   type Size_Type is range -Memory_Size / 2 .. Memory_Size / 2 - 1;");

      NL;
      PL ("   Unspecified_Size : constant Size_Type := Size_Type'First;");

      case Parameters.Variant is
         when Non_Tasking =>
            null;

         when Embedded_Tasking =>
            NL;
            PL
              (Default_Stack_Size_Template.Format
                 (VSS.Strings.Formatters.Integers.Image
                      (Parameters.Default_Stack_Size)));
            NL;
            PL
              (Minimum_Stack_Size_Parameter_Template.Format
                 (VSS.Strings.Formatters.Integers.Image
                      (Parameters.Minimum_Stack_Size)));
            NL;
            PL ("   function Adjust_Storage_Size (Size : Size_Type) return Size_Type is");
            PL ("     (if Size = Unspecified_Size then Default_Stack_Size");
            PL ("      elsif Size < Minimum_Stack_Size then Minimum_Stack_Size");
            PL ("      else Size);");

         when Full_Tasking =>
            NL;
            PL ("   function Default_Stack_Size return Size_Type;");
            NL;
            PL
              (Minimum_Stack_Size_Function_Template.Format
                 (VSS.Strings.Formatters.Integers.Image
                      (Parameters.Minimum_Stack_Size)));
            NL;
            PL ("   function Adjust_Storage_Size (Size : Size_Type) return Size_Type is");
            PL ("     (if Size = Unspecified_Size then Default_Stack_Size");
            PL ("      elsif Size < Minimum_Stack_Size then Minimum_Stack_Size");
            PL ("      else Size);");
      end case;

      --  if Parameters.Variant = Full_Tasking then
      --     "Default_Env_Stack_Size : constant Size_Type :=";
      --  end if;

      NL;
      if Parameters.Stack_Grows_Down then
         PL ("   Stack_Grows_Down : constant Boolean := True;");

      else
         PL ("   Stack_Grows_Down : constant Boolean := False;");
      end if;

      NL;
      PL
        (Runtime_Default_Sec_Stack_Size_Template.Format
          (VSS.Strings.Formatters.Integers.Image
             (Parameters.Runtime_Default_Sec_Stack_Size)));

      if Parameters.Variant = Full_Tasking then
         NL;
         if Parameters.Sec_Stack_Dynamic then
            PL ("   Sec_Stack_Dynamic : constant Boolean := True;");

         else
            PL ("   Sec_Stack_Dynamic : constant Boolean := False;");
         end if;
      end if;

      NL;
      PL ("   long_bits : constant := Long_Integer'Size;");
      NL;
      PL ("   ptr_bits  : constant := Standard'Address_Size;");
      PL ("   subtype C_Address is System.Address;");
      NL;
      PL ("   C_Malloc_Linkname : constant String := ""__gnat_malloc"";");

      if Parameters.Variant /= Non_Tasking then
         --  "   Garbage_Collected : constant Boolean := False;"

         NL;
         if Parameters.No_Abort then
            PL ("   No_Abort : constant Boolean := True;");

         else
            PL ("   No_Abort : constant Boolean := False;");
         end if;

         NL;
         PL
           (Max_Attribute_Count_Template.Format
              (VSS.Strings.Formatters.Integers.Image
                 (Parameters.Max_Attribute_Count)));
         NL;
         PL
           (Max_Task_Image_Length_Template.Format
              (VSS.Strings.Formatters.Integers.Image
                 (Parameters.Max_Task_Image_Length)));

         NL;
         PL
           (Default_Exception_Msg_Max_Length_Template.Format
              (VSS.Strings.Formatters.Integers.Image
                 (Parameters.Default_Exception_Msg_Max_Length)));
         --  This is probably should depends from "exceptions" feature
      end if;

      NL;
      PL ("end System.Parameters;");
   end Generate_Specification;

   --------------
   -- Generate --
   --------------

   procedure Generate
     (Runtime    : RTG.Runtime.Runtime_Descriptor'Class;
      Parameters : System_Parameters_Descriptor) is
   begin
      Generate_Specification (Runtime, Parameters);

      if Parameters.Variant = Full_Tasking then
         Generate_Body (Runtime, Parameters);
      end if;
   end Generate;

end RTG.System_Parameters;
