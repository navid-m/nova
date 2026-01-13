import bindbc.glfw;
import bindbc.opengl;
import std.stdio;

struct Nova
{
    GLFWwindow* window;
    bool running;

    void initialize(string title)
    {
        if (loadGLFW() != glfwSupport)
        {
            writeln("Could not load GLFW");
            return;
        }

        glfwInit();
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);

        window = glfwCreateWindow(1920, 1080, title.ptr, null, null);
        if (!window)
        {
            glfwTerminate();
            return;
        }

        glfwMakeContextCurrent(window);

        GLSupport glSupport = loadOpenGL();
        if (glSupport == GLSupport.noLibrary)
        {
            writeln("ERROR: Could not load OpenGL");
            return;
        }

        glViewport(0, 0, 1920, 1080);
        running = true;
    }

    void run()
    {
        while (running && !glfwWindowShouldClose(window))
        {
            glfwPollEvents();
            glClear(GL_COLOR_BUFFER_BIT);
            glfwSwapBuffers(window);
        }
    }

    void cleanup()
    {
        glfwDestroyWindow(window);
        glfwTerminate();
    }
}

void main()
{
    Nova engine;
    engine.initialize("Example game");
    engine.run();
    engine.cleanup();
}
