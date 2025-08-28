part of 'widgets.dart';

class FbTranslatedText extends Text {
  final bool translate;
  final bool translateAll;

  FbTranslatedText(
    super.data, {
    this.translate = true,
    this.translateAll = true,
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  });

  @override
  Widget build(BuildContext context) {
    String data = super.data ?? "";
    if (translate) {
      data = getTranslator().translate(data, replaceAll: translateAll);
    }
    return Text(
      data,
      key: super.key,
      style: super.style,
      strutStyle: super.strutStyle,
      textAlign: super.textAlign,
      textDirection: super.textDirection,
      locale: super.locale,
      softWrap: super.softWrap,
      overflow: super.overflow,
      textScaler: super.textScaler,
      maxLines: super.maxLines,
      semanticsLabel: super.semanticsLabel,
      semanticsIdentifier: super.semanticsIdentifier,
      textWidthBasis: super.textWidthBasis,
      textHeightBehavior: super.textHeightBehavior,
      selectionColor: super.selectionColor,
    );
  }
}
