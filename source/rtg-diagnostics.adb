--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Conversions;
with VSS.Strings.Formatters.Strings; use VSS.Strings.Formatters.Strings;
with VSS.Strings.Templates;          use VSS.Strings.Templates;
with VSS.Text_Streams.Standards;

package body RTG.Diagnostics is

   Error_Stream : VSS.Text_Streams.Output_Text_Stream_Access;

   -----------
   -- Error --
   -----------

   procedure Error (Text : VSS.Strings.Virtual_String) is
      use type VSS.Text_Streams.Output_Text_Stream_Access;

      Success : Boolean := True;

   begin
      if Error_Stream = null then
         Error_Stream :=
           new VSS.Text_Streams.Output_Text_Stream'Class'
             (VSS.Text_Streams.Standards.Standard_Output);
      end if;

      Error_Stream.Put_Line (Text, Success);

      raise Internal_Error;
   end Error;

   -----------
   -- Error --
   -----------

   procedure Error
     (File : GNATCOLL.VFS.Virtual_File; Text : VSS.Strings.Virtual_String)
   is
      Template : constant Virtual_String_Template := "{}: {}";

   begin
      Error
        (Template.Format
           (Image
              (VSS.Strings.Conversions.To_Virtual_String
                 (File.Display_Full_Name)),
            Image (Text)));
   end Error;

   -----------
   -- Error --
   -----------

   procedure Error
     (Template    : VSS.Strings.Templates.Virtual_String_Template;
      Parameter_1 : VSS.Strings.Virtual_String;
      Parameter_2 : VSS.Strings.Virtual_String;
      Parameter_3 : VSS.Strings.Virtual_String) is
   begin
      Error
        (Template.Format
           (Image (Parameter_1), Image (Parameter_2), Image (Parameter_3)));
   end Error;

   -------------
   -- Warning --
   -------------

   procedure Warning (Text : VSS.Strings.Virtual_String) is
      use type VSS.Text_Streams.Output_Text_Stream_Access;

      Success : Boolean := True;

   begin
      if Error_Stream = null then
         Error_Stream :=
           new VSS.Text_Streams.Output_Text_Stream'Class'
                 (VSS.Text_Streams.Standards.Standard_Output);
      end if;

      Error_Stream.Put_Line (Text, Success);
   end Warning;

   -------------
   -- Warning --
   -------------

   procedure Warning
     (File : GNATCOLL.VFS.Virtual_File; Text : VSS.Strings.Virtual_String)
   is
      Template : constant Virtual_String_Template := "{}: {}";

   begin
      Warning
        (Template.Format
           (Image
              (VSS.Strings.Conversions.To_Virtual_String
                 (File.Display_Full_Name)),
            Image (Text)));
   end Warning;

   -------------
   -- Warning --
   -------------

   procedure Warning
     (Template    : VSS.Strings.Templates.Virtual_String_Template;
      Parameter_1 : VSS.Strings.Virtual_String) is
   begin
      Warning (Template.Format (Image (Parameter_1)));
   end Warning;

end RTG.Diagnostics;
