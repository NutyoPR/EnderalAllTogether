#pragma once
// Plugin-wide forced include. CommonLibSSE-NG headers need SKSE/Impl/PCH.h first, and the
// generated __EnderalSTRPatchPlugin.cpp uses "..."sv at global scope, so std::literals must be global.
#include "SKSE/Impl/PCH.h"
#include "RE/Skyrim.h"
#include "SKSE/SKSE.h"

using namespace std::literals;
