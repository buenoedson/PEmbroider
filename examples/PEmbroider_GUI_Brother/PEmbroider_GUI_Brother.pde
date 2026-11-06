import processing.embroider.*;
import java.io.File;

PEmbroiderGraphics E;
PImage loadedImage = null;
String statusMessage = "Clique em 'Abrir Imagem' para comecar.";

// Dimensoes do bastidor da maquina (em mm)
int hoopWidth = 100;
int hoopHeight = 100;

// Parametros de bordado
float stitchSpacing = 4.0;
int fillMode = PEmbroiderGraphics.CONCENTRIC;

// Area util do canvas
int canvasX = 260;
int canvasY = 20;
int canvasSize = 660;

void setup() {
  size(940, 700);
  surface.setTitle("Bordador PEmbroider - Brother");
  initEmbroider();
}

void initEmbroider() {
  E = new PEmbroiderGraphics(this, hoopWidth * 10, hoopHeight * 10);
  E.setPESVersion(1); // Maxima compatibilidade Brother
}

void draw() {
  background(240);
  drawSidebar();
  drawHoopCanvas();
}

void drawSidebar() {
  fill(255);
  noStroke();
  rect(10, 10, 230, 680, 8);
  
  // Titulo
  fill(30);
  textSize(16);
  textAlign(LEFT, TOP);
  text("Controles de Bordado", 25, 25);
  
  // Botao Abrir Imagem
  drawButton(25, 60, 200, 36, "1. Abrir Imagem (PNG/JPG)", color(41, 128, 185));
  
  // Selecao de Bastidor Brother
  fill(60);
  textSize(13);
  text("2. Tamanho do Bastidor:", 25, 120);
  drawButton(25, 140, 95, 32, "10 x 10 cm", hoopWidth == 100 ? color(39, 174, 96) : color(149, 165, 166));
  drawButton(130, 140, 95, 32, "13 x 18 cm", hoopWidth == 130 ? color(39, 174, 96) : color(149, 165, 166));
  
  // Preenchimento
  fill(60);
  textSize(13);
  text("3. Tipo de Ponto:", 25, 195);
  drawButton(25, 215, 95, 30, "Concentrico", fillMode == PEmbroiderGraphics.CONCENTRIC ? color(142, 68, 173) : color(149, 165, 166));
  drawButton(130, 215, 95, 30, "Paralelo", fillMode == PEmbroiderGraphics.PARALLEL ? color(142, 68, 173) : color(149, 165, 166));
  
  // Espacamento
  fill(60);
  textSize(13);
  text("4. Espacamento: " + nf(stitchSpacing, 1, 1) + " mm", 25, 270);
  drawButton(25, 290, 95, 28, "Mais Denso (-)", color(127, 140, 141));
  drawButton(130, 290, 95, 28, "Menos Denso (+)", color(127, 140, 141));
  
  // Botao Exportar
  drawButton(25, 350, 200, 48, "Salvar Bordado (.PES)", color(231, 76, 60));
  
  // Status
  fill(80);
  textSize(12);
  text("Status:", 25, 430);
  fill(40);
  rect(25, 450, 200, 120, 4);
  fill(240);
  textSize(11);
  text(statusMessage, 32, 460, 186, 100);
}

void drawButton(int x, int y, int w, int h, String label, color bg) {
  fill(bg);
  stroke(200);
  rect(x, y, w, h, 6);
  fill(255);
  noStroke();
  textAlign(CENTER, CENTER);
  textSize(12);
  text(label, x + w / 2, y + h / 2);
}

void drawHoopCanvas() {
  fill(255);
  stroke(210);
  rect(canvasX, canvasY, canvasSize, canvasSize, 8);
  
  // Desenho do bastidor simulado
  stroke(180);
  noFill();
  float hoopScale = (canvasSize - 40.0) / max(hoopWidth, hoopHeight);
  float dw = hoopWidth * hoopScale;
  float dh = hoopHeight * hoopScale;
  float cx = canvasX + canvasSize / 2;
  float cy = canvasY + canvasSize / 2;
  
  rect(cx - dw / 2, cy - dh / 2, dw, dh, 12);
  
  // Grade central
  stroke(235);
  line(cx - dw / 2, cy, cx + dw / 2, cy);
  line(cx, cy - dh / 2, cx, cy + dh / 2);
  
  // Renderizacao dos pontos calculados pelo PEmbroider
  if (E != null && E.polylines.size() > 0) {
    pushMatrix();
    translate(cx - dw / 2, cy - dh / 2);
    scale(dw / (hoopWidth * 10.0), dh / (hoopHeight * 10.0));
    
    strokeWeight(2);
    stroke(0, 80, 200);
    noFill();
    for (int i = 0; i < E.polylines.size(); i++) {
      ArrayList<PVector> poly = E.polylines.get(i);
      beginShape();
      for (int j = 0; j < poly.size(); j++) {
        PVector pt = poly.get(j);
        vertex(pt.x, pt.y);
      }
      endShape();
    }
    popMatrix();
  }
}

void mousePressed() {
  // 1. Abrir Imagem
  if (isMouseOver(25, 60, 200, 36)) {
    selectInput("Selecione uma imagem para bordar:", "imageSelected");
  }
  
  // 2. Bastidor 10x10
  if (isMouseOver(25, 140, 95, 32)) {
    hoopWidth = 100;
    hoopHeight = 100;
    reprocessEmbroidery();
  }
  // 2. Bastidor 13x18
  if (isMouseOver(130, 140, 95, 32)) {
    hoopWidth = 130;
    hoopHeight = 180;
    reprocessEmbroidery();
  }
  
  // 3. Concentrico
  if (isMouseOver(25, 215, 95, 30)) {
    fillMode = PEmbroiderGraphics.CONCENTRIC;
    reprocessEmbroidery();
  }
  // 3. Paralelo
  if (isMouseOver(130, 215, 95, 30)) {
    fillMode = PEmbroiderGraphics.PARALLEL;
    reprocessEmbroidery();
  }
  
  // 4. Espacamento -
  if (isMouseOver(25, 290, 95, 28)) {
    stitchSpacing = max(1.5, stitchSpacing - 0.5);
    reprocessEmbroidery();
  }
  // 4. Espacamento +
  if (isMouseOver(130, 290, 95, 28)) {
    stitchSpacing = min(10.0, stitchSpacing + 0.5);
    reprocessEmbroidery();
  }
  
  // Salvar Bordado .PES
  if (isMouseOver(25, 350, 200, 48)) {
    if (E == null || E.polylines.size() == 0) {
      statusMessage = "Erro: Nenhuma imagem carregada para exportar.";
    } else {
      selectOutput("Salvar arquivo de bordado Brother (.pes):", "saveFileSelected");
    }
  }
}

boolean isMouseOver(int x, int y, int w, int h) {
  return (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h);
}

void imageSelected(File selection) {
  if (selection == null) {
    statusMessage = "Selecao de arquivo cancelada.";
    return;
  }
  loadedImage = loadImage(selection.getAbsolutePath());
  if (loadedImage != null) {
    statusMessage = "Imagem carregada: " + selection.getName();
    reprocessEmbroidery();
  } else {
    statusMessage = "Falha ao abrir o formato da imagem.";
  }
}

void reprocessEmbroidery() {
  if (loadedImage == null) return;
  
  initEmbroider();
  statusMessage = "Processando geometria de pontos...";
  
  E.beginDraw();
  E.clear();
  E.fill(20, 20, 20);
  E.noStroke();
  E.hatchMode(fillMode);
  E.hatchSpacing(stitchSpacing * 2.0);
  
  // Redimensionar proporcionalmente para o bastidor selecionado
  PImage img = loadedImage.copy();
  int targetW = hoopWidth * 10;
  int targetH = hoopHeight * 10;
  img.resize(targetW - 100, 0);
  if (img.height > targetH - 100) {
    img.resize(0, targetH - 100);
  }
  
  int posX = (targetW - img.width) / 2;
  int posY = (targetH - img.height) / 2;
  E.image(img, posX, posY);
  
  E.optimize();
  statusMessage = "Bordado pronto! Pontos gerados: " + countTotalStitches();
}

int countTotalStitches() {
  int count = 0;
  for (int i = 0; i < E.polylines.size(); i++) {
    count += E.polylines.get(i).size();
  }
  return count;
}

void saveFileSelected(File selection) {
  if (selection == null) {
    statusMessage = "Exportacao cancelada.";
    return;
  }
  String outPath = selection.getAbsolutePath();
  if (!outPath.toLowerCase().endsWith(".pes")) {
    outPath += ".pes";
  }
  E.setPath(outPath);
  E.endDraw();
  statusMessage = "Sucesso! Arquivo salvo em:\n" + outPath;
}

