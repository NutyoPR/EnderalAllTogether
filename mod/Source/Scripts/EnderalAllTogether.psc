Scriptname EnderalAllTogether Native Hidden
{Enderal AllTogether: shares small bits of world state with your Skyrim Together party (see EnderalAllTogether.dll).
Without the plugin these functions are unbound: IsLoaded() then returns False and scripts leave things alone.}

; True when the Enderal AllTogether plugin is installed.
Bool Function IsLoaded() global native

; Stores a value under a key and shares it with the party. Keys must not contain | = ;
Function ShareValue(String asKey, Int aiValue) global native

; The value stored under a key (yours or a party member's), or aiDefault if there is none.
; When a value arrives from the party, the mod event "EnderalAllTogether_Shared" is sent (strArg = key, numArg = value).
Int Function GetSharedValue(String asKey, Int aiDefault) global native
