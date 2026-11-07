# Build (from CachyOS, via GitHub Actions)

    cd EnderalSTRPatch
    git init -b main
    git submodule add https://github.com/CharmedBaryon/CommonLibSSE-NG extern/CommonLibSSE-NG
    git add . && git commit -m "EnderalSTRPatch scaffold"
    gh repo create EnderalSTRPatch --private --source=. --push    # or add a remote by hand

Then Actions tab -> latest run -> download the `EnderalSTRPatch` artifact (contains SKSE/Plugins/...).
If the build fails, copy the first compiler error from the log and send it back.
