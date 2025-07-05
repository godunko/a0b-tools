--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with VSS.Strings.Templates;

with RTG.Diagnostics;

package body RTG.Architecture is

   -------------
   -- Process --
   -------------

   procedure Process
     (Tasking              : RTG.Tasking.Tasking_Descriptor;
      Startup              : in out RTG.Startup.Startup_Descriptor;
      Scenarios            : in out RTG.GNAT_RTS_Sources.Scenario_Maps.Map;
      System_Parameters    : in out RTG.System.System_Descriptor;
      System_BB_Parameters : in out
        RTG.System_BB_Parameters.System_BB_Parameters_Descriptor)
   is
      use type VSS.Strings.Virtual_String;
      use all type RTG.System.GCC14.System_Implementation_Parameter;

      procedure Check_Set
        (Name  : VSS.Strings.Virtual_String;
         Value : VSS.Strings.Virtual_String);

      ---------------
      -- Check_Set --
      ---------------

      procedure Check_Set
        (Name  : VSS.Strings.Virtual_String;
         Value : VSS.Strings.Virtual_String)
      is
         Template : constant VSS.Strings.Templates.Virtual_String_Template :=
           "scenario ""{}"" is set to ""{}"", expected ""{}""";

      begin
         if Scenarios.Contains (Name) then
            if Scenarios (Name) /= Value then
               RTG.Diagnostics.Error (Template, Name, Scenarios (Name), Value);
            end if;

         else
            Scenarios.Insert (Name, Value);
         end if;
      end Check_Set;

   begin
      if not Scenarios.Contains ("dt:&cpu0:compatible") then
         RTG.Diagnostics.Error ("""dt:&cpu0:compatible"" is not specified");

      elsif Scenarios ("dt:&cpu0:compatible") = "arm,cortex-m3" then
         Check_Set ("CPU_Family", "arm");
         Check_Set ("Target_Word_Size", "32");
         Check_Set ("Has_FMA", "no");
         Check_Set ("Has_Compare_And_Swap", "yes");
         Check_Set ("Has_CHERI", "no");

         System_Parameters.Parameters (Backend_Divide_Checks)     := False;
         System_Parameters.Parameters (Backend_Overflow_Checks)   := True;
         System_Parameters.Parameters (Support_Atomic_Primitives) := True;
         System_Parameters.Parameters (Support_Long_Shifts)       := True;
         System_Parameters.Parameters (ZCX_By_Default)            := True;

         System_Parameters.Parameters (Denorm)                    := True;
         System_Parameters.Parameters (Machine_Overflows)         := False;
         System_Parameters.Parameters (Machine_Rounds)            := True;
         System_Parameters.Parameters (Signed_Zeros)              := True;

         if RTG.Tasking.Use_GNAT_Tasking (Tasking) then
            System_Parameters.Restrictions
              (RTG.System.GCC14.No_Task_At_Interrupt_Priority) := True;
         end if;

         System_BB_Parameters.ARM_Has_FPU := False;
         Startup.ARM_Enable_FPU           := False;

      elsif Scenarios ("dt:&cpu0:compatible") = "arm,cortex-m4f" then
         Check_Set ("CPU_Family", "arm");
         Check_Set ("Target_Word_Size", "32");
         Check_Set ("Has_FMA", "no");
         Check_Set ("Has_Compare_And_Swap", "yes");
         Check_Set ("Has_CHERI", "no");

         System_Parameters.Parameters (Backend_Divide_Checks)     := False;
         System_Parameters.Parameters (Backend_Overflow_Checks)   := True;
         System_Parameters.Parameters (Support_Atomic_Primitives) := True;
         System_Parameters.Parameters (Support_Long_Shifts)       := True;
         System_Parameters.Parameters (ZCX_By_Default)            := True;

         System_Parameters.Parameters (Denorm)                    := True;
         System_Parameters.Parameters (Machine_Overflows)         := False;
         System_Parameters.Parameters (Machine_Rounds)            := True;
         System_Parameters.Parameters (Signed_Zeros)              := True;

         if RTG.Tasking.Use_GNAT_Tasking (Tasking) then
            System_Parameters.Restrictions
              (RTG.System.GCC14.No_Task_At_Interrupt_Priority) := True;
         end if;

         System_BB_Parameters.ARM_Has_FPU := True;
         Startup.ARM_Enable_FPU           := True;

      else
         RTG.Diagnostics.Error ("unsupported ""dt:&cpu0:compatible""");
      end if;

      if not Scenarios.Contains ("dt:&cpu0:clock-frequency") then
         RTG.Diagnostics.Error
           ("""dt:&cpu0:clock-frequency"" is not specified");

      else
         System_BB_Parameters.Clock_Frequency :=
           Scenarios ("dt:&cpu0:clock-frequency");
      end if;

      if not Scenarios.Contains ("dt:&nvic:arm,num-irq-priority-bits") then
         RTG.Diagnostics.Error
           ("""dt:&nvic:arm,num-irq-priority-bits"" is not specified");

      else
         System_BB_Parameters.ARM_Num_IRQ_Priority_Bits :=
           Scenarios ("dt:&nvic:arm,num-irq-priority-bits");
      end if;
   end Process;

end RTG.Architecture;
