// Transforme la charte (`frontend/design/tokens.json`) en feuille de style du back-office
// (`src/styles/tokens.generated.css`) : variables CSS des thèmes Jour et Nuit + thème Tailwind.
//
// La charte reste la SEULE source : on ne recopie jamais une couleur ou une taille à la main.
// Après un changement de tokens.json : `npm run generate:tokens` ; le test `tool/tokens.test.ts`
// échoue tant que le fichier généré n'est pas à jour.
//
// Règles :
// - thème Jour par défaut (`:root`), thème Nuit sous `[data-theme="dark"]` (menu latéral, DA0.3) ;
// - mêmes noms de variables que `frontend/design/tokens.css` (`--bg`, `--surface-1`…), sauf les
//   ombres (`--ep-shadow-*`) : `--shadow-*` est le nom que Tailwind donne à ses propres ombres ;
// - dans Tailwind, SEULES les valeurs de la charte existent : couleurs, tailles de texte, rayons et
//   ombres par défaut de Tailwind sont retirés (« on n'invente pas de taille intermédiaire ») ;
// - le jeton `current` devient `current-base` dans Tailwind (`current` y désigne `currentColor`) ;
// - les espacements de la charte (4 px × n) sont exactement l'échelle de Tailwind : vérifié ici.

type Themed = { dark: string; light: string };
type ColorToken = { name: string; value: Themed };
type TypeStyle = {
  name: string;
  fontSize: string;
  lineHeight: string;
  fontWeight: number;
  letterSpacing?: string;
};
type Tokens = {
  color: { tokens: ColorToken[] };
  type: {
    families: Record<string, string>;
    groups: { name: string; family: string; styles: TypeStyle[] }[];
  };
  spacing: { tokens: { name: string; value: string }[] };
  radius: { tokens: { name: string; value: string }[] };
  shadow: { tokens: { name: string; value: Themed }[] };
  blur: { tokens: { name: string; value: string }[] };
};

/** Familles de la charte servies par `next/font` (variable CSS posée dans `src/app/layout.tsx`). */
const FONT_VARIABLES: Record<string, { tailwind: string; variable: string; first: string }> = {
  admin: { tailwind: "sans", variable: "--font-inter", first: "Inter" },
  mono: { tailwind: "mono", variable: "--font-jetbrains-mono", first: '"JetBrains Mono"' },
};

/** Noms réservés de Tailwind que la charte ne doit pas remplacer. */
const TAILWIND_RENAMES: Record<string, string> = { current: "current-base" };

export function generateTokensCss(tokensJson: string): string {
  const tokens = JSON.parse(tokensJson) as Tokens;
  const out: string[] = [
    "/* CODE GÉNÉRÉ depuis frontend/design/tokens.json : ne pas modifier à la main.",
    "   Régénérer : npm run generate:tokens (vérifié par tool/tokens.test.ts). */",
    "",
  ];

  for (const [selector, theme, label] of [
    [':root,\n[data-theme="light"]', "light", "Thème Jour (défaut du back-office)"],
    ['[data-theme="dark"]', "dark", "Thème Nuit (menu latéral)"],
  ] as const) {
    out.push(`/* ${label} */`, `${selector} {`, `  color-scheme: ${theme};`);
    for (const token of tokens.color.tokens) out.push(`  --${token.name}: ${token.value[theme]};`);
    for (const token of tokens.shadow.tokens) {
      out.push(`  --ep-${token.name}: ${token.value[theme]};`);
    }
    out.push("}", "");
  }

  checkSpacing(tokens.spacing.tokens);

  out.push("@theme inline {");
  out.push("  /* Seules les valeurs de la charte : rien d'autre dans Tailwind. */");
  for (const namespace of ["color", "text", "radius", "shadow", "font"]) {
    out.push(`  --${namespace}-*: initial;`);
  }
  for (const token of tokens.color.tokens) {
    const name = TAILWIND_RENAMES[token.name] ?? token.name;
    out.push(`  --color-${name}: var(--${token.name});`);
  }
  for (const group of tokens.type.groups) {
    for (const style of group.styles) {
      out.push(`  --text-${style.name}: ${style.fontSize};`);
      out.push(`  --text-${style.name}--line-height: ${style.lineHeight};`);
      out.push(`  --text-${style.name}--font-weight: ${style.fontWeight};`);
      if (style.letterSpacing) {
        out.push(`  --text-${style.name}--letter-spacing: ${style.letterSpacing};`);
      }
    }
  }
  for (const token of tokens.radius.tokens) out.push(`  --${token.name}: ${token.value};`);
  for (const token of tokens.shadow.tokens) out.push(`  --${token.name}: var(--ep-${token.name});`);
  for (const token of tokens.blur.tokens) out.push(`  --${token.name}: ${token.value};`);
  for (const [family, font] of Object.entries(FONT_VARIABLES)) {
    const stack = tokens.type.families[family];
    if (!stack?.startsWith(font.first)) {
      throw new Error(`Famille « ${family} » : ${font.first} attendue en tête de « ${stack} »`);
    }
    out.push(
      `  --font-${font.tailwind}: var(${font.variable}),${stack.slice(font.first.length + 1)};`,
    );
  }
  out.push("}", "");
  return out.join("\n");
}

/** `space-N` vaut N × 4 px : exactement `p-N`, `gap-N`… de Tailwind (pas de variable à générer). */
function checkSpacing(spacing: { name: string; value: string }[]): void {
  for (const { name, value } of spacing) {
    const step = Number(name.replace("space-", ""));
    if (value !== `${step * 4}px`) {
      throw new Error(`${name} = ${value} : la charte ne suit plus l'échelle de 4 px de Tailwind`);
    }
  }
}
