--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.JSON.Content_Handlers;
with VSS.JSON.Push_Readers.Simple;
with VSS.Strings.Conversions;
with VSS.Text_Streams.File_Input;

package body RTG.Runtime_Reader is

   type Content_Handler is
     new VSS.JSON.Content_Handlers.JSON_Content_Handler with record
      Scenarios : RTG.GNAT_RTS_Sources.Scenario_Maps.Map;

      Key       : VSS.Strings.Virtual_String;
   end record;

   overriding procedure Start_Document
     (Self : in out Content_Handler; Success : in out Boolean);

   overriding procedure End_Document
     (Self : in out Content_Handler; Success : in out Boolean);

   overriding procedure Start_Array
     (Self : in out Content_Handler; Success : in out Boolean);

   overriding procedure End_Array
     (Self : in out Content_Handler; Success : in out Boolean);

   overriding procedure Start_Object
     (Self : in out Content_Handler; Success : in out Boolean);

   overriding procedure End_Object
     (Self : in out Content_Handler; Success : in out Boolean);

   overriding procedure Key_Name
     (Self    : in out Content_Handler;
      Name    : VSS.Strings.Virtual_String'Class;
      Success : in out Boolean);

   overriding procedure String_Value
     (Self    : in out Content_Handler;
      Value   : VSS.Strings.Virtual_String'Class;
      Success : in out Boolean);

   overriding procedure Number_Value
     (Self    : in out Content_Handler;
      Value   : VSS.JSON.JSON_Number;
      Success : in out Boolean);

   overriding procedure Boolean_Value
     (Self    : in out Content_Handler;
      Value   : Boolean;
      Success : in out Boolean);

   overriding procedure Null_Value
     (Self : in out Content_Handler; Success : in out Boolean);

   overriding function Error_Message
     (Self : Content_Handler) return VSS.Strings.Virtual_String;

   -------------------
   -- Boolean_Value --
   -------------------

   overriding procedure Boolean_Value
     (Self    : in out Content_Handler;
      Value   : Boolean;
      Success : in out Boolean) is
   begin
      raise Program_Error;
   end Boolean_Value;

   ---------------
   -- End_Array --
   ---------------

   overriding procedure End_Array
     (Self : in out Content_Handler; Success : in out Boolean) is
   begin
      raise Program_Error;
   end End_Array;

   ------------------
   -- End_Document --
   ------------------

   overriding procedure End_Document
     (Self : in out Content_Handler; Success : in out Boolean) is
   begin
      null;
   end End_Document;

   ----------------
   -- End_Object --
   ----------------

   overriding procedure End_Object
     (Self : in out Content_Handler; Success : in out Boolean) is
   begin
      null;
   end End_Object;

   -------------------
   -- Error_Message --
   -------------------

   overriding function Error_Message
     (Self : Content_Handler) return VSS.Strings.Virtual_String is
   begin
      return VSS.Strings.Empty_Virtual_String;
   end Error_Message;

   --------------
   -- Key_Name --
   --------------

   overriding procedure Key_Name
     (Self    : in out Content_Handler;
      Name    : VSS.Strings.Virtual_String'Class;
      Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      Self.Key := VSS.Strings.Virtual_String (Name);
   end Key_Name;

   ----------------
   -- Null_Value --
   ----------------

   overriding procedure Null_Value
     (Self : in out Content_Handler; Success : in out Boolean) is
   begin
      raise Program_Error;
   end Null_Value;

   ------------------
   -- Number_Value --
   ------------------

   overriding procedure Number_Value
     (Self    : in out Content_Handler;
      Value   : VSS.JSON.JSON_Number;
      Success : in out Boolean) is
   begin
      raise Program_Error;
   end Number_Value;

   ----------
   -- Read --
   ----------

   procedure Read
     (File      : GNATCOLL.VFS.Virtual_File;
      Scenarios : out RTG.GNAT_RTS_Sources.Scenario_Maps.Map)
   is
      Input   : aliased VSS.Text_Streams.File_Input.File_Input_Text_Stream;
      Reader  : VSS.JSON.Push_Readers.Simple.JSON_Simple_Push_Reader;
      Handler : aliased Content_Handler;

   begin
      Input.Open
        (VSS.Strings.Conversions.To_Virtual_String (File.Display_Full_Name));
      Reader.Set_Stream (Input'Unchecked_Access);
      Reader.Set_Content_Handler (Handler'Unchecked_Access);

      Reader.Parse;

      Input.Close;

      Scenarios := Handler.Scenarios;
   end Read;

   -----------------
   -- Start_Array --
   -----------------

   overriding procedure Start_Array
     (Self : in out Content_Handler; Success : in out Boolean) is
   begin
      raise Program_Error;
   end Start_Array;

   --------------------
   -- Start_Document --
   --------------------

   overriding procedure Start_Document
     (Self : in out Content_Handler; Success : in out Boolean) is
   begin
      null;
   end Start_Document;

   ------------------
   -- Start_Object --
   ------------------

   overriding procedure Start_Object
     (Self : in out Content_Handler; Success : in out Boolean) is
   begin
      null;
   end Start_Object;

   ------------------
   -- String_Value --
   ------------------

   overriding procedure String_Value
     (Self    : in out Content_Handler;
      Value   : VSS.Strings.Virtual_String'Class;
      Success : in out Boolean)
   is
      pragma Unreferenced (Success);

   begin
      Self.Scenarios.Insert (Self.Key, VSS.Strings.Virtual_String (Value));
   end String_Value;

end RTG.Runtime_Reader;
