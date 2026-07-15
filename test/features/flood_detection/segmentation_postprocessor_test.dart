import 'package:ai_road_safety_platform/features/flood_detection/data/processors/segmentation_postprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const labels = ['background', 'road', 'water', 'vehicle', 'obstacle'];
  const post = SegmentationPostprocessor(labels: labels);

  test('computes water and road coverage from class map', () {
    // 2x2 map: road, water, water, vehicle
    final flat = <double>[1, 2, 2, 3];
    final decoded = post.process(flat: flat, shape: [1, 2, 2]);

    expect(decoded.stats.roadCoveragePercent, 25);
    expect(decoded.stats.waterCoveragePercent, 50);
    expect(decoded.stats.vehicleCoveragePercent, 25);
    expect(decoded.stats.obstacleCoveragePercent, 0);
    expect(decoded.stats.isFloodLikely, isTrue);
  });

  test('argmax NHWC logits pick dominant class', () {
    // 1x1x5 logits favouring water (index 2)
    final flat = <double>[-2, -1, 5, 0, 0];
    final decoded = post.process(flat: flat, shape: [1, 1, 1, 5]);

    expect(decoded.classIndices.single, 2);
    expect(decoded.stats.waterCoveragePercent, 100);
    expect(decoded.stats.meanConfidence, greaterThan(0.5));
  });

  test('builds transparent background in RGBA overlay', () {
    final rgba = post.buildRgbaOverlay(
      classIndices: const [0, 2],
      width: 2,
      height: 1,
      alpha: 100,
    );
    expect(rgba.length, 8);
    expect(rgba[3], 0); // background alpha
    expect(rgba[7], 100); // water alpha
  });
}
