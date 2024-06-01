{ lib
, openssl
, providers ? []
}:

let 
    openssl-with-providers = openssl.overrideAttrs (old: {
        name = "openssl-with-providers";
        postInstall = old.postInstall + ''
        ${
            lib.concatStringsSep "\n"
            (map
                (provider:
                ''
                    # Slightly dishonest, but print all the debug stuff first (more organized)
                    # ONLY WORKS FOR OQSPROVIDER RIGHT NOW
                    echo "Copying provider ${provider.name}"
                    echo cp -rs --no-preserve=mode "${provider}" "$out/lib/ossl-modules"
                    echo "Adding ${provider.name} to openssl.conf"
                    echo sed -i 's/\\[provider_sect\\]/[provider_sect]\n${provider.name} = ${provider.name}_sect/g' $etc/etc/ssl/openssl.cnf
                    
                    cp --no-preserve=mode ${provider}/lib/ossl-modules/* "$out/lib/ossl-modules"
                    
                    # sed -i '/^[[:space:]]*#/!s/\[provider_sect\]/[provider_sect]\n${provider.name} = ${provider.name}_sect/g' $etc/etc/ssl/openssl.cnf
                    # echo "[${provider.name}_sect]" >> $etc/etc/ssl/openssl.cnf
                    
                    sed -i '/^[[:space:]]*#/!s/\[provider_sect\]/[provider_sect]\noqsprovider = oqsprovider_sect/g' $etc/etc/ssl/openssl.cnf
                    echo "[oqsprovider_sect]" >> $etc/etc/ssl/openssl.cnf
                    echo "activate = 1" >> $etc/etc/ssl/openssl.cnf
                ''
                )
                providers
            )
        }
        echo Enable the default provider
        echo sed -i '/^[[:space:]]*#/!s/\[default_sect\]/[default_sect]\nactivate = 1/g' $etc/etc/ssl/openssl.cnf
        sed -i '/^[[:space:]]*#/!s/\[default_sect\]/[default_sect]\nactivate = 1/g' $etc/etc/ssl/openssl.cnf
        '';
  });

in
    openssl-with-providers
