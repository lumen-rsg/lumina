#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>

#include <stdio.h>

static int egl_error(const char *operation)
{
    fprintf(stderr, "%s failed: EGL error 0x%04x\n",
            operation, eglGetError());
    return 1;
}

int main(void)
{
    static const EGLint config_attributes[] = {
        EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
        EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
        EGL_RED_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_BLUE_SIZE, 8,
        EGL_NONE,
    };
    static const EGLint surface_attributes[] = {
        EGL_WIDTH, 16,
        EGL_HEIGHT, 16,
        EGL_NONE,
    };
    static const EGLint context_attributes[] = {
        EGL_CONTEXT_CLIENT_VERSION, 2,
        EGL_NONE,
    };
    EGLDisplay display;
    EGLConfig config;
    EGLSurface surface;
    EGLContext context;
    EGLint major;
    EGLint minor;
    EGLint config_count;
    GLenum gl_error;

    display = eglGetPlatformDisplay(EGL_PLATFORM_SURFACELESS_MESA,
                                    EGL_DEFAULT_DISPLAY, NULL);
    if (display == EGL_NO_DISPLAY)
        return egl_error("eglGetPlatformDisplay");
    if (!eglInitialize(display, &major, &minor))
        return egl_error("eglInitialize");
    if (!eglBindAPI(EGL_OPENGL_ES_API))
        return egl_error("eglBindAPI");
    if (!eglChooseConfig(display, config_attributes, &config, 1,
                         &config_count) || config_count != 1)
        return egl_error("eglChooseConfig");

    surface = eglCreatePbufferSurface(display, config, surface_attributes);
    if (surface == EGL_NO_SURFACE)
        return egl_error("eglCreatePbufferSurface");
    context = eglCreateContext(display, config, EGL_NO_CONTEXT,
                               context_attributes);
    if (context == EGL_NO_CONTEXT)
        return egl_error("eglCreateContext");
    if (!eglMakeCurrent(display, surface, surface, context))
        return egl_error("eglMakeCurrent");

    printf("EGL %d.%d\n", major, minor);
    printf("GL_VENDOR=%s\n", glGetString(GL_VENDOR));
    printf("GL_RENDERER=%s\n", glGetString(GL_RENDERER));
    printf("GL_VERSION=%s\n", glGetString(GL_VERSION));

    glClearColor(0.25f, 0.5f, 0.75f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glFinish();
    gl_error = glGetError();
    printf("GL_ERROR=0x%04x\n", gl_error);

    eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    eglDestroyContext(display, context);
    eglDestroySurface(display, surface);
    eglTerminate(display);
    return gl_error == GL_NO_ERROR ? 0 : 1;
}
