// eslint-rules/no-cross-layer-imports.js
const LAYER_ORDER = ['types', 'config', 'repo', 'service', 'runtime', 'ui'];

module.exports = {
  meta: {
    type: 'problem',
    docs: { description: 'Enforce architectural layer dependency direction' },
    messages: {
      crossLayerImport:
        'Layer "{{fromLayer}}" cannot import from "{{toLayer}}". ' +
        'Dependencies must flow: Types → Config → Repo → Service → Runtime → UI. ' +
        'If you need this data in {{fromLayer}}, expose it through a Provider interface.',
    },
  },
  create(context) {
    const filename = context.getFilename();

    function getLayer(filePath) {
      for (const layer of LAYER_ORDER) {
        if (filePath.includes(`/${layer}/`) || filePath.includes(`\\${layer}\\`)) {
          return layer;
        }
      }
      return null;
    }

    return {
      ImportDeclaration(node) {
        const fromLayer = getLayer(filename);
        const toLayer = getLayer(node.source.value);
        if (!fromLayer || !toLayer) return;
        const fromIndex = LAYER_ORDER.indexOf(fromLayer);
        const toIndex = LAYER_ORDER.indexOf(toLayer);
        if (toIndex > fromIndex) {
          context.report({
            node,
            messageId: 'crossLayerImport',
            data: { fromLayer, toLayer },
          });
        }
      },
    };
  },
};
