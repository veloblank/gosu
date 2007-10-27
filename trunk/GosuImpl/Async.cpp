#include <Gosu/Async.hpp>
#include <Gosu/Graphics.hpp>
#include <Gosu/Image.hpp>
#include <Gosu/Window.hpp>
#include <boost/bind.hpp>

using namespace boost;

namespace Gosu
{
    namespace
    {
        void asyncNewImage_Impl(Window& window, std::wstring filename, void* context,
                            shared_ptr<try_mutex> mutex,
                            shared_ptr<std::auto_ptr<Image> > result)
        {
            try_mutex::scoped_lock lock(*mutex);
            
            window.makeCurrentContext(context);
            result->reset(new Image(window.graphics(), filename));
            window.releaseContext(context);

        }
    }
}

Gosu::AsyncResult<Gosu::Image> Gosu::asyncNewImage(Window& window, const std::wstring& filename)
{
	shared_ptr<try_mutex> mutex(new try_mutex);
	shared_ptr<std::auto_ptr<Image> > image(new std::auto_ptr<Image>);
	thread thread(bind(asyncNewImage_Impl,
						ref(window), filename,
						window.createSharedContext(),
						ref(mutex), ref(image)));
	return AsyncResult<Image>(mutex, image);
}
