#!/bin/bash

# =======================================================================
# Script para busca de subdomínios
# Autor: Vagner Luz do Carmo (vluzrmos@gmail.com)
# -----------------------------------------------------------------------
# Descrição:
# Este script busca subdomínios de um domínio alvo utilizando várias 
# ferramentas (subfinder, alterx, dnsx e dig) para obter resultados
# detalhados e filtrados. A lista final contém subdomínios válidos 
# com suas respectivas entradas DNS.
#
# O script pode utilizar uma wordlist para ampliar a busca por subdomínios.
#
# -----------------------------------------------------------------------
# Modo de uso:
#   domain-finder -w <wordlist> <domain>
#   Exemplo:
#   domain-finder -w wordlist.txt example.com
#
# Parâmetros:
#   -w, -w=  : Caminho para a wordlist (opcional).
#   <domain> : Domínio a ser pesquisado.
#
# -----------------------------------------------------------------------
# Dependências:
# Certifique-se de ter as seguintes ferramentas instaladas e disponíveis 
# no seu PATH:
#   - subfinder
#   - alterx
#   - dnsx
#   - dig
#   - awk
#   - grep
#   - sed
#   - xargs
#
# Você pode instalar essas ferramentas usando:
#   go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
#   go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
#   go install -v github.com/projectdiscovery/alterx@latest
#
# -----------------------------------------------------------------------
# Notas:
# - O script ordena a saída final por subdomínio e tipo de registro DNS.
# - Usa `awk` para garantir que entradas duplicadas sejam removidas.
# - Usa `dig` para obter detalhes de registros DNS.
# - Caso uma wordlist seja fornecida, ela é usada no comando alterx.
# =======================================================================

DIR="$(cd "$(dirname "$0")" && pwd)"
WORDLISTS_DIR="/etc/domain-finder/wordlists"
POSITIONAL_ARGS=()

# Itera sobre todos os argumentos passados
while [[ $# -gt 0 ]]; do
    case "$1" in
        -w=*)
            # Caso o argumento seja no formato -w=valor
            WORDLIST="${1#-w=}"
            shift  # Move para o próximo argumento
            ;;
        -w)
            # Caso o argumento seja no formato -w valor
            WORDLIST="$2"
            shift 2  # Move para o próximo argumento (passando a opção e o valor)
            ;;
        -*)
            # Caso algum argumento comece com - ou --, mas não seja uma opção válida
            echo "Error: Invalid option '$1'." >> /dev/stderr
            exit 1
            ;;
        *)
            # Adiciona argumentos posicionais ao array
            POSITIONAL_ARGS+=("$1")
            shift  # Move para o próximo argumento
            ;;
    esac
done

DOMAIN="${POSITIONAL_ARGS[0]}"

if [ -z "$DOMAIN" ]; then
    echo "Usage: $0 -w <wordlist> <domain>"

    exit 1
fi

# Find the wordlist file
if [[ -n "$WORDLIST" && ! -f "$WORDLIST" ]]; then
    if [[ -f "$DIR/$WORDLIST" && -r "$DIR/$WORDLIST" ]]; then
        WORDLIST="$DIR/$WORDLIST"
    elif [[ -f "$DIR/wordlists/$WORDLIST" && -r "$DIR/wordlists/$WORDLIST" ]]; then
        WORDLIST="$DIR/wordlists/$WORDLIST"
    elif [[ -f "$WORDLISTS_DIR/$WORDLIST" && -r "$WORDLISTS_DIR/$WORDLIST" ]]; then
        WORDLIST="$WORDLISTS_DIR/$WORDLIST"
    fi
fi

if [[ -n "$WORDLIST" && ! -f "$WORDLIST" ]]; then
    echo "Error: Wordlist file '$WORDLIST' is not found or is not readable." >> /dev/stderr
    exit 1
fi

if [ -f "$WORDLIST" ]; then
    ALTERX_WORD="-pp word=$WORDLIST"
fi

{ 
    # Domínio inicial
    echo "$DOMAIN" |

    # Busca subdomínios com subfinder
    subfinder -silent -no-color | 

    # Gera uma nova lista com o domínio alvo e seus subdomínios da wordlist
    awk -v domain="$DOMAIN" -v alterxargs="$ALTERX_WORD" '
    { print $0 } 
    END { print domain }
    END {
        cmd="echo " domain " | alterx -silent " alterxargs;
        while (cmd | getline subdomain) { 
            print subdomain;
        }
        close(cmd);
    }' |

    # Remove linhas duplicadas
    awk '{if (!seen[$0]++) print $0}' |

    # Busca entradas DNS com dnsx
    # dnsx -silent -recon -no-color |

    # Formata a saída para ter apenas o domínio e o tipo de registro DNS
    # awk '{print $1, substr($2, 2, length($2) - 2)}' |

    # Remove linhas duplicadas
    # awk '{if (!seen[$0]++) print $0}' |

    # Executa dig para cada servidor para obter detalhes de registros DNS
    awk -v timeout=10 '
    {
        servers["google"]="@8.8.8.8";
        servers["cloudflare"]="@1.1.1.1";

        recon = "A AAAA CNAME MX NS TXT SOA CAA PTR SRV AFXR ANY";
        split(recon, types, " ");

        domain=$0;
        split("",queries)

        for (i in types) {
            queries[length(queries)+1]=domain " " types[i];
        }

        query=queries[1];
        for (i=2; i <= length(queries); i++) {
            query=query " " queries[i];
        }

        for (server in servers) {
            cmd="dig " servers[server] " +noall +answer +retry=5 +tries=5 +timeout=" timeout " " query " 2> /dev/null"
            
            while (cmd | getline result) { 
                print result;
            }
            close(cmd);
        }
    }
    '
    #|
    # Remove linhas inválidas como comentários, linhas em branco e registros SOA desnecessários
    # Verifica se o registro é do domínio alvo
    #awk -v domain="$DOMAIN." '/^[^; \.#]/ {if (match($1, domain "$")) print $0}' |

    # Gera uma chave para remover linhas duplicadas considerando o domínio, o tipo de registro DNS e o valor (incluindo a prioridade, no caso do MX)
    #awk '{key=$1 " " $4; for (i=5; i <= NF; i++) { key=key " " $i}; if (!seen[key]++) print $0}'
}
