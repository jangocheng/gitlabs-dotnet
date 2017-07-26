FROM ubuntu:16.04

# Enable SSL
RUN apt-get update \
    && apt-get install -y apt-transport-https curl tzdata

# Install .NET Core
RUN sh -c 'echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet-release/ xenial main" > /etc/apt/sources.list.d/dotnetdev.list' \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 417A0893 \
    && apt-get update \
    && apt-get install -y dotnet-dev-1.0.4 unzip

# Install mono
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb http://download.mono-project.com/repo/debian wheezy/snapshots/4.4.2 main" > /etc/apt/sources.list.d/mono-xamarin.list \
    && apt-get update \
    && apt-get install -y mono-devel \
    && rm -rf /var/lib/apt/lists/*

# Install NuGet
RUN mkdir -p /opt/nuget \
    && curl -Lsfo /opt/nuget/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe

# Prime dotnet
RUN mkdir dotnettest \
    && cd dotnettest \
    && dotnet new console -lang C# \
    && dotnet restore \
    && dotnet build \
    && dotnet run \
    && cd .. \
    && rm -r dotnettest

# Prime Cake
ADD cakeprimer cakeprimer
RUN cd cakeprimer \
    && dotnet restore Cake.sln \
    --source "https://www.myget.org/F/xunit/api/v3/index.json" \
    --source "https://dotnet.myget.org/F/dotnet-core/api/v3/index.json" \
    --source "https://dotnet.myget.org/F/cli-deps/api/v3/index.json" \
    --source "https://api.nuget.org/v3/index.json" \
    && cd .. \
    && rm -rf cakeprimer

# Cake
ENV CAKE_VERSION 0.21.1
RUN mkdir -p /opt/Cake/Cake \
    && curl -Lsfo Cake.zip "https://www.myget.org/F/cake/api/v2/package/Cake/$CAKE_VERSION" \
    && unzip -q Cake.zip -d "/opt/Cake/Cake" \
    && rm -f Cake.zip

ADD cake /usr/bin/cake
RUN chmod 755 /usr/bin/cake

# Test Cake
RUN mkdir caketest \
    && cd caketest \
    && cake --version \
    && cd .. \
    && rm -rf caketest

# Display info installed components
RUN mono --version
RUN dotnet --info
RUN apt-get clean
