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

# check wordlist file exists

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
    dnsx -silent -recon -no-color |

    # Formata a saída para ter apenas o domínio e o tipo de registro DNS
    awk '{print $1, substr($2, 2, length($2) - 2)}' |

    # Remove linhas duplicadas
    awk '{if (!seen[$0]++) print $0}' |

    # Executa dig para cada servidor para obter detalhes de registros DNS
    awk -v timeout=10 '
    {
        servers["google"]="@8.8.8.8";
        servers["cloudflare"]="@1.1.1.1";

        for (server in servers) {
            cmd="dig " $0 " " servers[server] " +nocomments +nostats +nocmd +noshowsearch +nosearch +noquestion +timeout=" timeout " 2>/dev/null"
            while (cmd | getline result) { 
                print result;
            }
            close(cmd);
        }
    }
    ' |
    # Remove linhas inválidas como comentários, linhas em branco e registros SOA desnecessários
    # Verifica se o registro é do domínio alvo
    awk -v domain="$DOMAIN." '/^[^; \.#]/ {if (match($1, domain "$")) print $0}' |

    # Gera uma chave para remover linhas duplicadas considerando o domínio, o tipo de registro DNS e o valor (incluindo a prioridade, no caso do MX)
    awk '{key=$1 " " $4; for (i=5; i <= NF; i++) { key=key " " $i}; if (!seen[key]++) print $0}'
}