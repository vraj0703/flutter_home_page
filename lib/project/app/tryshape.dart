import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gl/flutter_gl.dart';

import 'package:three_dart/three_dart.dart' as three;

class WebGlGeometryShapes extends StatefulWidget {
  final String fileName;
  const WebGlGeometryShapes({Key? key, required this.fileName}) : super(key: key);

  @override
  State<WebGlGeometryShapes> createState() => _MyAppState();
}

class _MyAppState extends State<WebGlGeometryShapes> {
  late FlutterGlPlugin three3dRender;
  three.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late three.Scene scene;
  late three.Camera camera;
  late three.Mesh mesh;
  late three.Group group;
  late three.Texture texture;

  double dpr = 1.0;

  bool verbose = true;
  bool disposed = false;

  late three.WebGLRenderTarget renderTarget;

  dynamic sourceTexture;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr
    };

    await three3dRender.initialize(options: options);

    setState(() {});

    // Wait for web
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return SingleChildScrollView(child: _build(context));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          render();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
                width: width,
                height: height,
                color: Colors.black,
                child: Builder(builder: (BuildContext context) {
                  return three3dRender.isInitialized
                      ? HtmlElementView(viewType: three3dRender.textureId!.toString())
                      : Container();
                })),
          ],
        ),
      ],
    );
  }

  render() {
    int t = DateTime.now().millisecondsSinceEpoch;

    final gl = three3dRender.gl;

    renderer!.render(scene, camera);

    int t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${t1 - t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
    gl.flush();

    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
    Map<String, dynamic> options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };
    renderer = three.WebGLRenderer(options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = false;

    if (!kIsWeb) {
      var pars = three.WebGLRenderTargetOptions(
          {"minFilter": three.LinearFilter, "magFilter": three.LinearFilter, "format": three.RGBAFormat});
      renderTarget = three.WebGLMultisampleRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
    }
  }

  initScene() {
    initRenderer();
    initPage();
  }

  initPage() async {
    scene = three.Scene();

    camera = three.PerspectiveCamera(50, width / height, 1, 2000);
    // let camra far
    camera.position.set(0, 150, 1500);
    scene.add(camera);

    var light = three.PointLight(0xffffff, 0.8);
    camera.add(light);

    group = three.Group();
    group.position.y = 50;
    scene.add(group);

    var loader = three.TextureLoader(null);
    texture = await loader.loadAsync("assets/planet.jpg", null);

    // it's necessary to apply these settings in order to correctly display the texture on a shape geometry

    texture.wrapS = texture.wrapT = three.RepeatWrapping;
    texture.repeat.set(0.008, 0.008);

    // Triangle

    var triangleShape =
    three.Shape(null).moveTo(80.0, 20.0).lineTo(40.0, 80.0).lineTo(120.0, 80.0).lineTo(80.0, 20.0); // close path

    // Heart

    double x = 0, y = 0;

    var heartShape = three.Shape(null) // From http://blog.burlock.org/html5/130-paths
        .moveTo(x + 25, y + 25)
        .bezierCurveTo(x + 25, y + 25, x + 20, y, x, y)
        .bezierCurveTo(x - 30, y, x - 30, y + 35, x - 30, y + 35)
        .bezierCurveTo(x - 30, y + 55, x - 10, y + 77, x + 25, y + 95)
        .bezierCurveTo(x + 60, y + 77, x + 80, y + 55, x + 80, y + 35)
        .bezierCurveTo(x + 80, y + 35, x + 80, y, x + 50, y)
        .bezierCurveTo(x + 35, y, x + 25, y + 25, x + 25, y + 25);


    // Circle

    double circleRadius = 40;
    var circleShape = three.Shape(null)
        .moveTo(0, circleRadius)
        .quadraticCurveTo(circleRadius, circleRadius, circleRadius, 0)
        .quadraticCurveTo(circleRadius, -circleRadius, 0, -circleRadius)
        .quadraticCurveTo(-circleRadius, -circleRadius, -circleRadius, 0)
        .quadraticCurveTo(-circleRadius, circleRadius, 0, circleRadius);






    var extrudeSettings = {
      "depth": 8,
      "bevelEnabled": true,
      "bevelSegments": 2,
      "steps": 2,
      "bevelSize": 1,
      "bevelThickness": 1
    };


    // addShape( shape, color, x, y, z, rx, ry,rz, s );

   addShape(circleShape, extrudeSettings, 0x00f000, 120, 250, 0, 0, 0, 0, 1);

    //

    animate();
  }

  addShape(shape, extrudeSettings, color, double x, double y, double z, double rx, double ry, double rz, double s) {
    // flat shape with texture
    // note: default UVs generated by THREE.ShapeGeometry are simply the x- and y-coordinates of the vertices

    three.TextureLoader(three.LoadingManager()).load(
      'assets/planet.jpg', // Your asset path
          (texture) {
        //log('Planet texture loaded successfully.');
        final geometry = three.SphereGeometry(64, 32, 32);
        final material = three.MeshStandardMaterial({
          'map': texture,
          'roughness': 0.4,
        });
        var earth = three.Mesh(geometry, material);
        scene.add(earth);
      },
    );

    var geometry = three.ShapeGeometry(shape);

    var mesh = three.Mesh(geometry, three.MeshPhongMaterial({"side": three.DoubleSide, "map": texture}));
    mesh.position.set(x, y, z - 175.0);
    mesh.rotation.set(rx, ry, rz);
    mesh.scale.set(s, s, s);
    group.add(mesh);

    // flat shape

    geometry = three.ShapeGeometry(shape);

    mesh = three.Mesh(geometry, three.MeshPhongMaterial({"color": color, "side": three.DoubleSide}));
    mesh.position.set(x, y, z - 125.0);
    mesh.rotation.set(rx, ry, rz);
    mesh.scale.set(s, s, s);
    group.add(mesh);

    // extruded shape

    var geometry2 = three.ExtrudeGeometry([shape], extrudeSettings);

    mesh = three.Mesh(geometry2, three.MeshPhongMaterial({"color": color}));
    mesh.position.set(x, y, z - 75.0);
    mesh.rotation.set(rx, ry, rz);
    mesh.scale.set(s, s, s);
    group.add(mesh);

    addLineShape(shape, color, x, y, z, rx, ry, rz, s);
  }

  addLineShape(shape, color, double x, double y, double z, double rx, double ry, double rz, double s) {
    // lines

    shape.autoClose = true;

    var points = shape.getPoints();
    var spacedPoints = shape.getSpacedPoints(50);

    var geometryPoints = three.BufferGeometry().setFromPoints(points);
    var geometrySpacedPoints = three.BufferGeometry().setFromPoints(spacedPoints);

    // solid line

    var line = three.Line(geometryPoints, three.LineBasicMaterial({"color": color}));
    line.position.set(x, y, z - 25);
    line.rotation.set(rx, ry, rz);
    line.scale.set(s, s, s);
    group.add(line);

    // line from equidistance sampled points

    line = three.Line(geometrySpacedPoints, three.LineBasicMaterial({"color": color}));
    line.position.set(x, y, z + 25);
    line.rotation.set(rx, ry, rz);
    line.scale.set(s, s, s);
    group.add(line);

    // vertices from real points

    var particles = three.Points(geometryPoints, three.PointsMaterial({"color": color, "size": 4}));
    particles.position.set(x, y, z + 75);
    particles.rotation.set(rx, ry, rz);
    particles.scale.set(s, s, s);
    group.add(particles);

    // equidistance sampled points

    particles = three.Points(geometrySpacedPoints, three.PointsMaterial({"color": color, "size": 4}));
    particles.position.set(x, y, z + 125);
    particles.rotation.set(rx, ry, rz);
    particles.scale.set(s, s, s);
    group.add(particles);
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    // mesh.rotation.x += 0.005;
    // mesh.rotation.z += 0.01;

    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }

  @override
  void dispose() {
    print(" dispose ............. ");
    disposed = true;
    three3dRender.dispose();

    super.dispose();
  }
}
