-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (c) 2026 Ahmad Ali Parr. All rights reserved.
-- Authored by Ahmad Ali Parr.
procedure Ada_Fixture is
   X : Integer := 1;
begin
   X := X + 1;
   pragma Assert (X = 2);
end Ada_Fixture;
