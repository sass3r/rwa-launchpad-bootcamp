# CURSOR.md — RWA Launchpad Bootcamp

Guía para el agente de Cursor en este repositorio. Léela antes de editar contratos, frontends o scripts.

## Qué es

Starter del bootcamp de Oppia Education Bolivia. En tres días cada equipo construye el mismo launchpad de activos del mundo real (RWA) en Soroban, sumando una capa SEP por día. Admin (`mint`, whitelist, `withdraw`, pause) y usuario (`invest`, `balance`, `transfer`) van separados a propósito; esa división llega hasta los scripts de deploy del día 3.

El token de pago lo despliega el instructor en testnet. El equipo no despliega su propio payment token: guarda la dirección en `AssetInfo.payment_token` al inicializar.

## Mapa del repo

No hay workspace de Cargo ni paquete npm compartido. Cada día es una copia independiente (copy-forward), no un symlink.

| Día | Contrato | Frontend | SEP | Alcance |
|-----|----------|----------|-----|---------|
| 1 | `dia-1/` | `frontend/dia-1/` | SEP-1 | `initialize`, `stellar.toml`, tests y build |
| 2 | `dia-2/` | `frontend/dia-2/` | SEP-41 | `balance`, `mint`, `transfer`, `set_whitelist`, errores, eventos, auth, variación |
| 3 | `dia-3/` | `frontend/dia-3/` | SEP-10/45 + deploy | `invest`, `withdraw`, `pause`, `unpause`, scripts, demo de 3 minutos |

- Empieza en `dia-1/`. El día 2 abre `dia-2/` (extiende el scaffold ya resuelto). El día 3 abre `dia-3/` (extiende el contrato del día 2).
- Un cambio en un día no se propaga solo. Si hay que llevarlo a otro día, cópialo a mano y solo cuando el usuario lo pida.
- El entregable final es el contrato de `dia-3/` en testnet más la demo de [`dia-3/DEMO.md`](dia-3/DEMO.md).

## Contrato Soroban

- Rust `no_std`, `soroban-sdk` 26, crate-type `cdylib`. Target de build: `wasm32v1-none`.
- Contrato: `RwaLaunchpad` en `src/lib.rs`. Tests en `src/test.rs`. Snapshots en `test_snapshots/`.
- Montos en `i128`. `invest` hace división entera: `rwa_amount = payment_amount / price_per_unit` (el resto se descarta).
- `total_supply` se guarda en `AssetInfo` y hoy no limita `mint` ni `invest`. No añadas ese tope salvo que el usuario lo pida.

### Storage

| Clave | Tipo | Contenido |
|-------|------|-----------|
| `Admin`, `AssetInfo` | instance | admin y metadatos del activo |
| `Balance(Address)`, `Whitelisted(Address)` | persistent | saldos y whitelist |

### Errores (`Error`, días 2 y 3)

| Código | Variante |
|--------|----------|
| 1 | `NotInitialized` |
| 2 | `AlreadyInitialized` |
| 3 | `InsufficientBalance` |
| 4 | `InvalidAmount` |
| 5 | `NotWhitelisted` |
| 6 | `Paused` |

Los panics de test usan `Error(Contract, #N)`. Auth inválida: `HostError: Error(Auth, InvalidAction)`.

### Funciones por día

**Día 1.** Solo `initialize`. El resto son `todo!()`.

**Día 2.** `balance`, `mint`, `transfer`, `set_whitelist`. Eventos `mint` y `transfer`. `mint` y `transfer` exigen `require_auth` del firmante y rechazan pausa e importes `<= 0`.

**Día 3.** Lo anterior más `pause`, `unpause`, `invest`, `withdraw`.

- `invest`: auth del inversor, `check_variation_gate`, no pausado, importe `> 0`, whitelist, precio `> 0`, unidades resultantes `> 0`. Transfiere el payment token del inversor al contrato y luego hace mint interno.
- `withdraw`: auth del admin. Mueve payment tokens del contrato a tesorería con `authorize_as_current_contract` y `token::Client::transfer`.

### Variación de equipo

Cada equipo elige una regla de acceso (pase de inversor verificado, saldo mínimo de otro activo, cupos limitados, etc.).

- Día 2: implementarla en `check_variation_gate`. Hoy es `todo!("cada equipo define su regla de acceso aquí")`.
- Día 3: `invest` llama esa puerta antes de mintear. El default es `Ok(())`; hay que pegar ahí la lógica del día 2.

### Bug plantado (no lo “arregles”)

En `dia-2/src/lib.rs`, `set_whitelist` no llama `admin.require_auth()`. Es el ejercicio del día 2. El test `test_set_whitelist_requires_admin` está escrito para fallar hasta que el alumno añada el check. El día 3 ya incluye `admin.require_auth()`.

No cierres ese hueco, no silencies el test y no copies el `set_whitelist` del día 3 al día 2, salvo que el usuario pida completar el ejercicio.

## Frontend

Tres apps Next.js 15 (App Router), React 19, TypeScript, Tailwind 4. Cada una habla con el contrato de su día vía Soroban RPC y Freighter. Son demos de bootcamp, no producción.

| App | Páginas | Contrato |
|-----|---------|----------|
| `frontend/dia-1` | `/`, `/initialize` | solo `initialize`; el resto se lista como no disponible |
| `frontend/dia-2` | `/`, `/admin`, `/user` | initialize, mint, whitelist, balance, transfer |
| `frontend/dia-3` | `/`, `/admin`, `/invest` | lo del día 2 más invest, withdraw, pause, unpause |

Estructura repetida en cada app (no extraigas un paquete compartido salvo que lo pidan):

- `app/` — páginas cliente (`"use client"`).
- `components/ui/` — `Button`, `Card`, `FormBits`. `components/layout/Header.tsx`. `components/ContractGate.tsx` muestra estado vacío si falta el contract id.
- `lib/config.ts` — env y `isContractConfigured()`.
- `lib/stellar/contract.ts` — invoke/simulación. `wallet.ts` y `wallet-context.tsx` — Freighter. `network.ts` — passphrase.
- `lib/errors.ts` — códigos de contrato a mensaje de UI.
- `frontend-design/` — tokens Oppia (colores, tipografía, spacing, card, button). Marca en `public/brand/`.
- `public/.well-known/stellar.toml` — SEP-1 que sirve la app.

Variables (`frontend/dia-N/.env.local`, a partir de `.env.example`):

- `NEXT_PUBLIC_CONTRACT_ID` — id `C…` del contrato de ese día.
- `NEXT_PUBLIC_PAYMENT_TOKEN_ID` — SAC / token de pago del instructor.
- `NEXT_PUBLIC_ADMIN_ADDRESS` — `G…` que habilita `/admin` (días 2 y 3).
- `NEXT_PUBLIC_NETWORK` — `testnet` por defecto; también `public` o `futurenet`.
- `NEXT_PUBLIC_SOROBAN_RPC_URL` — opcional; default `https://soroban-testnet.stellar.org`.

Sin `NEXT_PUBLIC_CONTRACT_ID`, las páginas que tocan la red deben mostrar el estado vacío, no reventar.

`AssetInfo` en el cliente es un `ScVal` map con las mismas claves que el struct Rust: `name` (symbol), `total_supply` y `price_per_unit` (`i128`), `payment_token` (address), `paused` (bool).

El README de `frontend/dia-3` dice `cd frontend`; el directorio correcto es `frontend/dia-3`.

## Scripts del día 3

`dia-3/scripts/admin-tool.sh` firma con la clave admin (`initialize`, `set_whitelist`, `mint`, `withdraw`, `pause`, `unpause`). `user-tool.sh` firma con el inversor (`invest`, `balance`, `transfer`). Placeholders `C...` y `G...` hay que sustituirlos; no los commitees con secretos. Las claves viven en el Stellar CLI (`stellar keys`), no en el repo.

## Comandos

Contrato (desde el día que se esté tocando):

```bash
cd dia-1   # o dia-2 / dia-3
cargo test
stellar contract build
```

WASM de release: `target/wasm32v1-none/release/rwa_launchpad_dia_N.wasm`.

Frontend:

```bash
cd frontend/dia-1   # o dia-2 / dia-3
npm install
cp .env.example .env.local
npm run dev        # http://localhost:3000
npm run lint
npm run build
```

Testnet (día 1): `stellar keys generate alice --network testnet` y `stellar keys fund alice --network testnet`.

## Cómo trabajar aquí

- Responde al usuario en español. Comentarios de código y READMEs existentes están en inglés; no los reescribas por idioma.
- Toca solo el día (contrato y/o frontend) que corresponda a la tarea. No “adelantes” funciones de un día posterior.
- Mantén la simetría admin/usuario: una función de admin exige la dirección admin y `require_auth`; una de usuario exige la del inversor o holder.
- Nuevos errores de contrato: siguiente código `u32`, variante en el enum, y el mensaje en `lib/errors.ts` del frontend de ese día.
- Tests con `soroban-sdk` `testutils`: `env.register`, cliente generado, `mock_all_auths` o `mock_auths` cuando el caso es de auth. El día 3 usa `register_stellar_asset_contract_v2` como payment token.
- UI: componentes funcionales, tokens de `frontend-design/`, estados vacío / error / éxito de transacción ya existentes (`ContractGate`, `FormError`, `TxSuccess`). Tras un cambio visible, verifica el flujo en el navegador (o, si no hay browser, `npm run build` / `npm run lint` del frontend tocado) e indica qué no se pudo comprobar.
- No edites `package-lock.json` a mano. No añadas archivos markdown que el usuario no haya pedido.
- Secretos, `.env.local` y claves de testnet no van al repo.
