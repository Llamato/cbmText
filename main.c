#include "libs/glad/glad.h"
#include "libs/glad/khrplatform.h"
#include <GLFW/glfw3.h>
#include <stddef.h>
#include <stdio.h>
#include "libs/common.h"
#include "cbmcharmode.h"
#include <math.h>

#define INITIAL_WINDOW_WIDTH 1024
#define INITIAL_WINDOW_HEIGHT 1024
#define CBM_CHARGEN_FILENAME "charsets/c64.bin"
#define TEXT_VERTEX_SHADER_FILENAME "shaders/cbmcharmode.vert"
#define TEXT_FRAGMENT_SHADER_FILENAME "shaders/cbmcharmode.frag"
#define FRAME_RATE 50
#define FRAME_TIME 1 / FRAME_RATE
#define WELCOME_SCREEN_DURATION 5 * FRAME_RATE
#define WASH_LEFT_ANIMATION_DURATION 1 * FRAME_RATE
#define SLOW_WRITE_CHARSET_ANIMATION_DURATION 5 * FRAME_RATE

// Event handlers
unsigned int currentWindowWidth = INITIAL_WINDOW_WIDTH;
unsigned int currentWindowHeight = INITIAL_WINDOW_WIDTH;

void windowResizeCallback(GLFWwindow *window, int width, int height) {
  glViewport(0, 0, width, height);
  currentWindowWidth = width;
  currentWindowHeight = height;
}

unsigned int windowIsFocused = 1;
void windowFocusCallback(GLFWwindow *window, int focused) {
  windowIsFocused = focused;
}

void blankColumn(struct cbmScreen* screen, unsigned int column) {
    for(unsigned int currentRow = 0; currentRow < CBM_SCREEN_ROWS; currentRow++) {
        size_t currentChar = CBM_SCREEN_COLUMNS * currentRow + column;
        screen->chars[currentChar] = CBM_SCREENCODE_CLEAR_CHAR;
    }
}

void welcomeScreen(struct cbmScreen* screen) {
    struct cbmScreenPosition statusPosition = {0, 0};
    writeStringToCbmScreen(screen, statusPosition, "Welcome\nand thank you for checking out cbmText", CBM_COLOR_WHITE);
}

void washLeftAnimation(struct cbmScreen* screen, size_t currentFrame, size_t durationFrames) {
    size_t blankingColumnIndex = currentFrame / durationFrames * CBM_SCREEN_COLUMNS;
    blankColumn(screen, blankingColumnIndex);
}

void slowWriteCharsetAnimation(struct cbmScreen* screen, size_t currentFrame, size_t durationFrames) {
    size_t cbmCharromCharCount = CBM_CHARSET_CHARCOUNT;
    size_t charsToPrint = round(cbmCharromCharCount * currentFrame / durationFrames);
    for(size_t currentChar = 0; currentChar < charsToPrint; currentChar++) {
        screen->chars[currentChar] = currentChar;
        screen->colors[currentChar] = CBM_COLOR_PINK;
    }
}

unsigned long long frameCount = 0;
int main(int argc, char* argv[]){
    //OpenGL, glfw and glad init
    int glfwstatus = glfwInit();
    if(!glfwstatus){
        printf("%s\n", "Failed to init glfw");
    }
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    GLFWwindow *window = glfwCreateWindow(INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT, "Spacer3000", NULL, NULL);
    glfwSetWindowSizeCallback(window, windowResizeCallback);
    glfwSetWindowFocusCallback(window, windowFocusCallback);
    if(window == NULL){
        printf("%s\n", "Failed to create GLFW window");
    }
    glfwMakeContextCurrent(window);
    if(!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress)){
        printf("Failed to initialize GLAD with GLFW loader\n");
        return -1;
    }
    glViewport(0, 0, INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT);

    //CbmText setup
    struct Vector2 textScreenPosition = {0.0f, 0.0f};
    struct Vector2 textScreenDimensions = {1.0f, 1.0f};
    char* c64GraphCharset = loadChargen(CBM_CHARGEN_FILENAME);
    char* c64CasedCharset = c64GraphCharset+CBM_CHARSET_SIZE;
    struct cbmScreen demoScreen = makeCbmScreen(textScreenPosition, textScreenDimensions, c64CasedCharset, c64colorPallet);
    clearCbmScreen(&demoScreen);

    //text Shader setup
    const char *textVertexShaderSource = readShaderFile(TEXT_VERTEX_SHADER_FILENAME);
    GLuint textVertexShader = makeGlShader(textVertexShaderSource, GL_VERTEX_SHADER);
    const char *textFragmentShaderSource = readShaderFile(TEXT_FRAGMENT_SHADER_FILENAME);
    GLuint textFragmentShader = makeGlShader(textFragmentShaderSource, GL_FRAGMENT_SHADER);
    GLuint textShaderProgram = glCreateProgram();
    linkGlShaders(textShaderProgram, textVertexShader, textFragmentShader);
    makeTextShaderObject(textShaderProgram, &demoScreen.glData);

    //Rendering loop
    while(!glfwWindowShouldClose(window)){
        glfwPollEvents();
        clearCbmScreen(&demoScreen);
        if(frameCount < WELCOME_SCREEN_DURATION){
            welcomeScreen(&demoScreen);
        }
        if(frameCount >= WELCOME_SCREEN_DURATION) {
            washLeftAnimation(&demoScreen, frameCount - WELCOME_SCREEN_DURATION, WASH_LEFT_ANIMATION_DURATION);
        }
        if(frameCount >= WELCOME_SCREEN_DURATION + WASH_LEFT_ANIMATION_DURATION) {
            slowWriteCharsetAnimation(&demoScreen, frameCount - (WELCOME_SCREEN_DURATION + WASH_LEFT_ANIMATION_DURATION), SLOW_WRITE_CHARSET_ANIMATION_DURATION);
        }
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        drawCbmScreen(&demoScreen, currentWindowWidth, currentWindowHeight);

        glfwSwapBuffers(window);
        frameCount++;
        if(frameCount > WELCOME_SCREEN_DURATION + WASH_LEFT_ANIMATION_DURATION + SLOW_WRITE_CHARSET_ANIMATION_DURATION) {
            sleep(1);
            frameCount = 0; 
        }
    }
}